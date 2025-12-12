# RAG (Retrieval-Augmented Generation) Usage in Hacker Tools

## What is RAG?

RAG (Retrieval-Augmented Generation) combines **vector similarity search** with **LLM generation** to provide context-aware responses. Instead of relying solely on the LLM's training data, RAG:

1. **Retrieves** relevant content from your database using semantic search (embeddings)
2. **Augments** the LLM prompt with this retrieved context
3. **Generates** responses that are grounded in your actual data

## Current RAG Implementation

### SubmissionRagService (`app/services/submission_rag_service.rb`)

**Current Usage**: Enhances search results by providing contextual summaries

**How it works**:
1. User searches for submissions
2. System retrieves top-K similar submissions using vector embeddings
3. These submissions are used as context for the LLM
4. LLM generates enhanced summaries explaining why each result is relevant
5. Enhanced results are displayed to the user

**Example Flow**:
```
User Query: "React state management"
  ↓
Vector Search → Find top 5 similar submissions about React/state management
  ↓
LLM Prompt: "Given these 5 submissions about React, explain why Submission X is relevant to 'React state management'"
  ↓
Enhanced Summary: "This submission discusses Redux, a popular React state management library, and compares it to Context API..."
```

## Potential RAG Use Cases for Better UX

### 1. **Interactive Submission Form - Smart Suggestions** ⭐ (High Priority)

**Problem**: When user pastes a URL, we want to show them similar submissions before they submit.

**RAG Solution**:
- As user pastes URL, generate embedding for the URL
- Find top 3-5 similar submissions using vector similarity
- Use RAG to generate a summary: "This looks similar to [submission X] about [topic Y]. Would you like to add to that discussion or create a new submission?"
- Show user the similar submissions with explanations

**Benefits**:
- Prevents duplicate submissions
- Helps users discover related content
- Improves content organization

**Implementation**:
```ruby
# In SubmissionController#validate_url (new action)
def validate_url
  url = params[:url]
  query_embedding = RubyLLM.embed(url, model: "text-embedding-3-small")
  
  # Find similar submissions
  similar = Submission.where("embedding <=> ? < 0.7", query_embedding)
                      .limit(5)
  
  # Use RAG to explain similarity
  context = build_similarity_context(similar, url)
  explanation = SubmissionRagService.explain_similarity(url, similar, context)
  
  render json: {
    similar_submissions: similar,
    explanation: explanation,
    should_warn: similar.any?
  }
end
```

### 2. **Submission Recommendations - "You Might Also Like"**

**Problem**: After viewing a submission, users want to discover related content.

**RAG Solution**:
- When user views a submission, find top 5 similar submissions
- Use RAG to generate personalized recommendations: "If you liked this article about React, you might also like these submissions about Vue.js and Angular..."
- Show recommendations with explanations

**Benefits**:
- Increases engagement
- Helps users discover more content
- Improves content discovery

**Implementation**:
```ruby
# In SubmissionController#show
def show
  @submission = Submission.find(params[:id])
  
  # Find similar submissions
  similar = find_similar_submissions(@submission, limit: 5)
  
  # Use RAG to generate recommendations
  @recommendations = SubmissionRagService.recommend(
    @submission,
    similar,
    user: current_user # Optional: personalize based on user's interests
  )
end
```

### 3. **Smart Tag Suggestions During Submission**

**Problem**: Users don't always know what tags to add to their submission.

**RAG Solution**:
- After metadata extraction, find similar submissions
- Use RAG to analyze: "Based on similar submissions about React and TypeScript, this submission should be tagged with: React, TypeScript, Frontend, Tutorial"
- Suggest tags with explanations

**Benefits**:
- Improves tag consistency
- Reduces manual tagging effort
- Better content organization

**Implementation**:
```ruby
# In ContentEnrichmentJob (after tool detection)
def suggest_tags_from_similar(submission)
  similar = find_similar_submissions(submission, limit: 10)
  
  # Use RAG to suggest tags
  tag_suggestions = SubmissionRagService.suggest_tags(
    submission,
    similar_submissions: similar
  )
  
  # Apply suggested tags (with user approval in future)
  tag_suggestions.each { |tag_name| add_tag_if_exists(submission, tag_name) }
end
```

### 4. **Question Answering About Submissions**

**Problem**: Users want to ask questions about submissions (e.g., "What tools are mentioned in this article?")

**RAG Solution**:
- User asks a question about a submission
- System retrieves the submission + related submissions as context
- LLM answers the question using the retrieved context

**Benefits**:
- Natural language interaction
- Answers grounded in actual data
- Better user experience

**Implementation**:
```ruby
# New action: SubmissionController#ask
def ask
  @submission = Submission.find(params[:id])
  question = params[:question]
  
  # Find related submissions for context
  related = find_similar_submissions(@submission, limit: 5)
  
  # Use RAG to answer
  answer = SubmissionRagService.answer_question(
    question: question,
    submission: @submission,
    context: related
  )
  
  render json: { answer: answer }
end
```

### 5. **Content Summarization with Context**

**Problem**: Long submissions need better summaries that consider related content.

**RAG Solution**:
- When generating a summary, retrieve similar submissions
- Use RAG to create a summary that explains how this submission relates to others
- Example: "This article about React hooks builds on concepts from [related submission] and introduces advanced patterns..."

**Benefits**:
- More informative summaries
- Better content understanding
- Shows relationships between submissions

**Implementation**:
```ruby
# In SummarizationJob (future)
def generate_contextual_summary(submission)
  similar = find_similar_submissions(submission, limit: 5)
  
  summary = SubmissionRagService.summarize_with_context(
    submission,
    similar_submissions: similar
  )
  
  submission.update(summary: summary)
end
```

### 6. **Smart Duplicate Detection with Explanations**

**Problem**: Current duplicate detection is binary (yes/no). Users want to understand why something is a duplicate.

**RAG Solution**:
- When detecting duplicates, use RAG to explain the similarity
- "This submission is similar to [existing submission] because both discuss React state management, mention Redux, and target intermediate developers..."
- Show explanation to user with option to proceed or link to existing submission

**Benefits**:
- Better user understanding
- Reduces confusion
- Helps users make informed decisions

**Implementation**:
```ruby
# In DuplicateCheckJob
def check_duplicate_with_explanation(submission_id)
  result = check_duplicate(submission_id)
  
  if result[:duplicate]
    existing = Submission.find(result[:duplicate_id])
    
    # Use RAG to explain similarity
    explanation = SubmissionRagService.explain_duplicate(
      new_submission: submission,
      existing_submission: existing
    )
    
    result[:explanation] = explanation
  end
  
  result
end
```

## RAG Architecture Pattern

All RAG implementations follow this pattern:

```
1. User Input (query, submission, question, etc.)
   ↓
2. Vector Search → Retrieve top-K similar submissions
   ↓
3. Build Context → Format retrieved submissions as context
   ↓
4. LLM Prompt → Create prompt with context + user input
   ↓
5. LLM Generation → Generate response using context
   ↓
6. Parse & Return → Extract structured data from LLM response
```

## Performance Considerations

1. **Caching**: Cache embeddings and similarity results
2. **Async Processing**: RAG can be slow - use background jobs for non-critical features
3. **Top-K Selection**: Limit context size (typically 3-5 submissions)
4. **Model Selection**: Use cheaper models (gpt-4o-mini) for RAG when possible
5. **Batch Processing**: Process multiple requests together when possible

## Cost Optimization

1. **Two-Stage RAG**: 
   - Stage 1: Fast vector search (cheap)
   - Stage 2: LLM generation only for top results (expensive)
2. **Conditional RAG**: Only use RAG when similarity score is above threshold
3. **Caching**: Cache LLM responses for similar queries
4. **Model Selection**: Use gpt-4o-mini for most RAG tasks, gpt-4o only for critical features

## Implementation Priority

1. **High Priority** (Immediate):
   - Interactive submission form with similar submissions (prevents duplicates)
   - Smart duplicate detection with explanations

2. **Medium Priority** (Next Phase):
   - Submission recommendations
   - Smart tag suggestions

3. **Low Priority** (Future):
   - Question answering
   - Contextual summarization

## Example: Enhanced SubmissionRagService

```ruby
class SubmissionRagService
  # New method: Explain why submissions are similar
  def self.explain_similarity(new_url, similar_submissions, options = {})
    return nil if similar_submissions.empty?
    
    context = build_similarity_context(similar_submissions, new_url)
    
    prompt = <<~PROMPT
      A user is about to submit: #{new_url}
      
      We found these similar existing submissions:
      #{context}
      
      Explain why these submissions are similar and whether the user should:
      1. Create a new submission (if content is different)
      2. Link to existing submission (if it's a duplicate)
      3. Add to existing discussion (if it's related)
      
      Format as JSON:
      {
        "similarity_score": 0.0-1.0,
        "explanation": "Why they're similar...",
        "recommendation": "create_new" | "link_existing" | "add_to_discussion",
        "recommended_submission_id": <id> or null
      }
    PROMPT
    
    chat = RubyLLM.chat(model: "gpt-4o-mini")
    response = chat.ask(prompt)
    parse_json_response(response.content)
  end
  
  # New method: Recommend submissions
  def self.recommend(submission, similar_submissions, options = {})
    user = options[:user]
    
    context = build_recommendation_context(submission, similar_submissions, user)
    
    prompt = <<~PROMPT
      User just viewed: #{submission.submission_name}
      
      Similar submissions:
      #{context}
      
      Generate personalized recommendations explaining why each submission is relevant.
      
      Format as JSON array:
      [
        {
          "submission_id": <id>,
          "reason": "Why this is recommended...",
          "relevance_score": 0.0-1.0
        }
      ]
    PROMPT
    
    chat = RubyLLM.chat(model: "gpt-4o-mini")
    response = chat.ask(prompt)
    parse_json_response(response.content)
  end
end
```

## Summary

RAG transforms our application from simple search to intelligent, context-aware interactions. By combining vector embeddings with LLM generation, we can:

- **Prevent duplicates** with smart explanations
- **Recommend content** based on similarity and context
- **Answer questions** about submissions
- **Suggest tags** based on related content
- **Enhance summaries** with contextual information

The key is to use RAG strategically - for features that benefit from understanding relationships and context, not just keyword matching.

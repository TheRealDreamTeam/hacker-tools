# RAG Implementation Decision

**Date**: 2025-12-12  
**Status**: RAG Disabled for Search, Planned for Future Use

## Decision

RAG (Retrieval-Augmented Generation) has been **disabled for search functionality** to improve performance and reduce costs. RAG will be implemented later for more targeted, high-value use cases.

## Rationale

### Why Disable RAG in Search?

1. **Performance**: RAG adds significant latency to search results (LLM API calls are slow)
2. **Cost**: LLM API calls are expensive, especially for every search query
3. **User Experience**: Search should be fast - users expect instant results
4. **Current Search Quality**: Hybrid search (full-text + semantic) already provides good results without RAG

### Why Keep RAG for Future Use?

RAG is valuable for specific, high-impact use cases where:
- The user is already engaged (viewing a specific item)
- The context is clear (viewing a tool/submission)
- The value is high (discovering related content, preventing duplicates)
- The latency is acceptable (user is already reading, not waiting for search)

## Current Search Implementation

Search currently uses:
- **Full-text search** (PostgreSQL `pg_search` with trigram)
- **Semantic search** (vector embeddings with cosine similarity)
- **Hybrid ranking** (combines both methods)

This provides fast, relevant results without RAG enhancement.

## Planned RAG Implementation

### 1. Linked Content Suggestions (High Priority)

**When**: User views a Tool or Submission show page

**What**: Show "You might also like" section with related items

**How**:
- Find top 5-10 similar items using embeddings
- Use RAG to generate personalized recommendations with explanations
- Display on show page sidebar or bottom section

**Benefits**:
- Increases engagement
- Helps users discover related content
- Better UX than simple similarity list

### 2. New Submission Similarity Explanation (High Priority)

**When**: User pastes URL in new submission form

**What**: Explain why similar submissions are similar

**How**:
- Find similar submissions using embeddings
- Use RAG to generate explanation: "This looks similar to [submission X] because [reason]"
- Show explanation in validation results

**Benefits**:
- Prevents duplicate submissions
- Helps users make informed decisions
- Improves content organization

## Implementation Status

- ✅ **RAG Service Created**: `SubmissionRagService` exists and is functional
- ✅ **RAG Documentation**: Complete documentation in `docs/RAG_USAGE.md`
- ❌ **Search Enhancement**: Disabled (commented out in `SubmissionsController`)
- ⏳ **Linked Suggestions**: Not yet implemented
- ⏳ **Similarity Explanation**: Partially implemented (method exists but not used)

## Code Locations

- **RAG Service**: `app/services/submission_rag_service.rb`
- **Search Controller**: `app/controllers/submissions_controller.rb` (RAG disabled)
- **Validation Controller**: `app/controllers/submissions_controller.rb#validate_url` (RAG optional, not enabled)
- **Documentation**: `docs/RAG_USAGE.md`, `docs/RAG_DECISION.md`

## Future Work

1. **Implement Linked Suggestions**:
   - Add `recommend` method to `SubmissionRagService`
   - Add recommendations to Tool/Submission show pages
   - Create recommendations partial

2. **Enhance Similarity Explanation**:
   - Implement `explain_similarity` method in `SubmissionRagService`
   - Use in `validate_url` action
   - Display explanations in form validation UI

3. **Performance Optimization**:
   - Cache RAG responses for similar queries
   - Use cheaper models (gpt-4o-mini) for RAG
   - Batch process recommendations

## Notes

- RAG service remains in codebase for future use
- All RAG functionality is optional and can be enabled when needed
- Search performance is prioritized over enhanced summaries
- RAG will be used where it provides the most value (contextual recommendations, not search)

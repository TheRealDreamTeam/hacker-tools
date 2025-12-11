# Submission Process Improvement - Design Document

**Status**: Planning  
**Last Updated**: 2025-12-11  
**Related**: `docs/SPECIFICATION.md`

## Executive Summary

The current system treats all user-submitted links as "tools," but users actually submit diverse content types (GitHub repos, documentation, articles, guides, social posts, code snippets, etc.) about tools. This is a **community-driven sharing platform** where users contribute content, not own tools. This document outlines a redesign to:

1. **Separate Tools and Submissions**: Tools are community-owned top-level entities (ideas/topics like "React", "Git"), while Submissions are user-contributed content about those tools
2. **User Ownership Model**: Users don't own tools - they submit content about tools. User dashboard shows "My Submissions" not "My Tools"
3. **Automatically classify** submissions by type (article, guide, repo, post, etc.)
4. **Auto-create Tools**: When a submission references a tool that doesn't exist, automatically create the Tool instance (community resource)
5. **Enrich submissions** asynchronously with metadata, tags, and tool associations
6. **Prevent duplicates** and filter inappropriate content (with two-stage safety checks)
7. **Improve search** with PostgreSQL full-text search (`pg_search`)
8. **Future: Posts**: Submissions can be text-only posts (like Twitter) that generate associations and appear on user profiles/feeds (future phases)
9. **Simple Phase 1**: Focus on link submissions, basic search, simple RubyLLM integration - build foundation for later phases

## Current State Analysis

### Existing Tool Model

**Current Structure:**
- Model: `Tool` (`app/models/tool.rb`)
- Attributes: `tool_name`, `tool_description`, `tool_url`, `author_note`, `visibility`
- Associations: `belongs_to :user`, `has_many :tags`, `has_many :comments`, `has_many :lists`
- Active Storage: `icon`, `picture` attachments
- Validations: URL format, presence of name/URL

**Current Submission Flow:**
1. User provides `tool_url` and optional `author_note` (free text) - **ONLY these two fields**
2. System derives `tool_name` from URL hostname automatically
3. **No user input for tags, description, or images** - all must be added manually later if needed
4. No automatic content enrichment
5. No duplicate detection
6. No content safety checks
7. Basic ILIKE search on `tool_name`, `tool_description`, and `tags.tag_name` (very limited)

**Limitations:**
- Name "tool" is misleading - users submit various content types
- No automatic classification of submission type
- No async processing pipeline
- No duplicate link prevention
- No content safety validation
- No automatic metadata extraction
- No intelligent relationship discovery
- **Very basic search** - only ILIKE queries on name, description, tags (no semantic search, no full-text search)
- **No follow integration** - submissions can be followed (polymorphic follows exist) but no notifications when followed content updates
- **No notification system** - planned but not yet implemented

## Problem Statement

### Core Issues

1. **Terminology Mismatch**: "Tool" doesn't accurately describe what users submit (links to repos, articles, docs, guides, etc.)
2. **Manual Work**: Users must manually add descriptions, tags, images - no automatic enrichment
3. **No Type Classification**: System doesn't distinguish between GitHub repos, documentation, articles, guides, etc.
4. **Duplicate Submissions**: Same link can be submitted multiple times
5. **Content Safety**: No validation to prevent inappropriate or dangerous content
6. **No Relationships**: Submissions aren't automatically connected to related tools/content
7. **Limited Metadata**: No automatic extraction of title, description, images, tags from submitted links

### User Goals

- Submit a link and free text description (author_note) - **minimal user input required**
- System automatically enriches the submission (tags, images, description, metadata)
- System prevents duplicate submissions
- System filters inappropriate content
- System connects submissions to related content
- System categorizes submissions appropriately
- **Enhanced search and discovery** - find content semantically, not just keyword matching
- **Notifications** - get notified when followed content (submissions, tags, users) has updates
- **Better discovery** - find related content through embeddings and RAG

## Proposed Solution Architecture

### Conceptual Model

**Core Entities:**
- **Tool**: Community-owned top-level entity representing any software-related concept, technology, service, or platform that users want to follow and search for. Tools are shared community resources, not user-owned.
- **Submission**: User-contributed content - can be a link with free text OR a text-only post. Users submit content about tools, they don't own the tools themselves.
- **Content Types**: Various types of submissions (article, guide, documentation, GitHub repo, social post, code snippet, post/text-only, etc.)

**Community-Driven Platform:**
- Users contribute content (submissions) about tools
- Tools are community resources - no user ownership
- Users can link to their own repos/projects, but the focus is on community sharing
- User dashboard shows "My Submissions" (content they've contributed), not "My Tools"
- Discussion and organization happen around community-shared content

### What is a Tool?

A **Tool** is any software-related entity that users want to follow, search for, and discover content about. Tools are not limited to software applications - they encompass a broad range of categories:

**1. Programming Languages**
- Python, JavaScript, Ruby, Go, Rust, Java, C++, TypeScript, etc.

**2. Frameworks**
- Frontend: React, Vue, Angular, Svelte, Next.js, Remix
- Backend: Rails, Django, Express, FastAPI, Spring Boot
- Mobile: React Native, Flutter, SwiftUI

**3. Libraries**
- Utility: Lodash, Axios, Moment.js
- UI: Material-UI, Tailwind CSS, Bootstrap
- Data: Pandas, NumPy, D3.js

**4. Development Tools**
- Version Control: Git, SVN, Mercurial
- Code Editors/IDEs: VS Code, Vim, Emacs, IntelliJ
- Package Managers: npm, yarn, pip, bundler, cargo

**5. Infrastructure & DevOps**
- Containers: Docker, Kubernetes, Podman
- Cloud Platforms: AWS, GCP, Azure, Heroku, Vercel, Netlify
- CI/CD: GitHub Actions, CircleCI, Jenkins, GitLab CI
- Infrastructure as Code: Terraform, Ansible, Pulumi

**6. Databases & Data Stores**
- Relational: PostgreSQL, MySQL, SQLite
- NoSQL: MongoDB, Redis, Cassandra, Elasticsearch
- Time Series: InfluxDB, TimescaleDB

**7. Build Tools & Bundlers**
- Webpack, Vite, esbuild, Rollup, Parcel
- Make, CMake, Gradle, Maven

**8. Testing Frameworks**
- Unit: Jest, RSpec, pytest, Mocha
- E2E: Cypress, Playwright, Selenium
- Integration: Supertest, Capybara

**9. Monitoring & Observability**
- APM: Datadog, New Relic, AppDynamics
- Error Tracking: Sentry, Rollbar, Bugsnag
- Logging: ELK Stack, Splunk, Loggly

**10. APIs & Services**
- Payment: Stripe, PayPal
- Communication: Twilio, SendGrid
- Authentication: Auth0, Firebase Auth, Clerk
- Storage: AWS S3, Cloudinary, Imgix

**11. Protocols & Standards**
- HTTP/HTTPS, GraphQL, REST, WebSocket
- OAuth, JWT, OpenID Connect

**12. Operating Systems** (in development context)
- Linux, macOS, Windows, WSL

**13. Security Tools**
- OWASP ZAP, Burp Suite, Snyk, Dependabot

**14. Documentation Tools**
- JSDoc, Sphinx, MkDocs, Docusaurus

**15. Design Tools** (if relevant to development)
- Figma, Sketch, Adobe XD

**Key Principle:** If users would want to follow it, search for it, and discover content about it, it qualifies as a Tool. Tools are the primary entities that users interact with - submissions are content about those tools.

**Key Insight:**
- **Tools** are community-owned top-level entities representing any software-related concept - users follow and search for tools, but don't own them
- **Submissions** are user-contributed content (links or posts) about tools - users own their submissions, not the tools
- **User Ownership Model**: 
  - Users own their submissions (content they've contributed)
  - Tools are community resources (no user ownership)
  - User dashboard: "My Submissions" (not "My Tools")
  - Users can link to their own repos/projects, but tools remain community entities
- **Automatic Tool Creation**: If a submission references a tool that doesn't exist on the platform:
  - Create the submission as its appropriate type (article, guide, post, etc.)
  - Automatically create a Tool instance as a community resource
  - Link the submission to the newly created tool
- **Submissions Can Be Posts**: 
  - Submissions can be text-only posts (like Twitter posts) - future feature
  - Posts generate associations to tools through text analysis
  - Posts appear on user profiles and feeds (future phases)
  - Phase 1 focuses on link submissions, posts are future consideration
- **Follow System Integration**: Both Tools and Submissions are followable (polymorphic `Follow` model exists) - need to integrate notifications
- **Search & Discovery**: Current search is very basic - need improved full-text search, and eventually semantic search with embeddings

### Data Model Changes

#### Option A: Rename Tool to Submission (Recommended)

**New Model: `Submission`**
- Keep `Tool` model as top-level entity (tools are community-owned ideas/topics like "React", "Git")
- Create new `Submission` model for user-contributed content (links or posts)
- `Submission` belongs_to `User` (user owns their submission)
- `Submission` belongs_to `Tool` (optional - submission can be about a tool)
- Add `submission_type` enum (article, guide, documentation, github_repo, social_post, code_snippet, website, post, other)
  - Note: `post` type for text-only submissions (future feature, Phase 1 focuses on links)
- Add `status` enum (pending, processing, completed, failed, rejected)
- Add `processed_at` (datetime)
- Add `metadata` (JSONB) - store extracted data (title, description, image_url, etc.)
- Add `normalized_url` (string, unique index, nullable) - for duplicate detection (null for text-only posts)
- Add `duplicate_of_id` (references :submission) - for duplicate detection
- Add `embedding` (vector, float[]) - for future semantic search (PostgreSQL pgvector or store in Redis)
- Keep existing associations (user, tags, comments, lists, follows)
- **Follow system already exists** - both Tools and Submissions are followable via polymorphic `Follow` model
- **User Dashboard**: Users see "My Submissions" (content they've contributed), not "My Tools"

**Tool Model Updates:**
- Keep `Tool` model as-is (it's the community-owned top-level entity)
- Remove `belongs_to :user` - tools are not user-owned (community resources)
- Add `has_many :submissions` association
- Tools can have multiple submissions (articles, guides, repos, posts about that tool)
- Tools are created automatically when referenced in submissions

**Migration Strategy:**
- Create migration to rename table and columns
- Update all references throughout codebase
- Maintain backward compatibility during transition

#### Option B: Keep Tool, Add Submission (Alternative)

**New Model: `Submission`**
- Separate model for user submissions
- `Submission` can link to existing `Tool` or create new `Tool`
- More complex but preserves existing Tool model

**Recommendation: Option A** - Cleaner architecture, better reflects actual use case

### Submission Types

**Enum: `submission_type`**
```ruby
enum submission_type: {
  article: 0,          # Blog post, article, tutorial
  guide: 1,            # How-to guide, tutorial
  documentation: 2,    # Official documentation
  github_repo: 3,      # GitHub repository (can be user's own repo)
  social_post: 4,      # Twitter/X, LinkedIn, etc. (external link)
  code_snippet: 5,     # Code example, gist
  website: 6,          # Company/product website
  video: 7,            # YouTube, Vimeo, etc.
  podcast: 8,          # Podcast episode
  post: 9,             # Text-only post (like Twitter post) - future feature
  other: 10            # Catch-all
}
```

**Note:** 
- Tools are separate community-owned top-level entities. Submissions are user-contributed content about tools.
- **Phase 1 Focus**: Link submissions (article, guide, repo, etc.) - `post` type is future consideration
- **Future: Posts**: Text-only submissions that generate tool associations and appear on user profiles/feeds
- Users can submit links to their own repos/projects, but tools remain community resources

### Categories - Removed

**Decision:** Categories are not needed. The existing Tag system with hierarchical structure already provides sufficient organization:
- Tags can represent categories (e.g., "Frontend", "Backend", "DevOps")
- Tags have parent-child relationships for hierarchy
- Tags are more flexible and user-driven
- Adding categories would be redundant

**If categories are needed in the future**, they can be added as a special tag type or as a separate model, but for now, tags are sufficient.

## Content Processing Pipeline

### Overview

When a user submits a link, the system should:

1. **Immediate Response**: Create submission record with `status: :pending`
2. **Async Processing**: Queue background jobs for all processing steps
3. **Parallel Execution**: Run multiple checks/processes concurrently
4. **Progressive Updates**: Update submission status and metadata as processing completes
5. **Real-time Updates**: Use Turbo Streams to update UI as processing progresses

### Processing Steps (Async)

#### 1. Duplicate Detection
**Job**: `SubmissionDuplicateCheckJob`
- Check if URL (normalized) already exists in database
- Normalize URL (remove trailing slashes, query params, fragments)
- Also check for similar/close links (not exact duplicates) using URL similarity
- If exact duplicate found:
  - Set `duplicate_of_id` to existing submission
  - Set `status: :rejected`
  - **User Experience**: Show user a message with link to the original submission
  - Return early (skip other processing)
- If similar links found (but not exact duplicate):
  - Store similar submission IDs in `metadata['similar_submissions']`
  - **User Experience**: Show user 2-3 closely related submissions
  - Ask user if they want to add to an existing submission or continue with new one
  - Continue processing (don't block)

#### 2. Content Safety Validation (Two-Stage)
**Job**: `SubmissionSafetyCheckJob`

**Stage 1: Programmatic Check (Fast, Low Cost)**
- Check URL against known bad link patterns
- Check domain against blacklist
- Check for common malicious URL patterns
- Validate URL format and accessibility
- If fails Stage 1:
  - Set `status: :rejected`
  - Log rejection reason
  - Return early (skip expensive LLM check)

**Stage 2: Deep LLM Validation (Only if Stage 1 passes)**
- Use RubyLLM with OpenAI API to analyze scraped content
- Check for:
  - Pornography
  - Violence/gore
  - Completely unrelated to software/tech
  - Malicious content
  - Spam or low-quality content
- If unsafe:
  - Set `status: :rejected`
  - Log rejection reason
  - Return early

**Cost Optimization**: Stage 1 filters out obvious bad links before expensive LLM calls.

#### 3. Content Scraping & Metadata Extraction
**Job**: `SubmissionMetadataExtractionJob`
- Scrape submitted URL for:
  - Title (from `<title>`, Open Graph, Twitter Cards)
  - Description (from meta description, Open Graph)
  - Images (from Open Graph image, Twitter Card image, first image on page)
  - Author information
  - Publication date
- Store in `metadata` JSONB column
- Update `submission_name` and `submission_description` from extracted data

#### 4. Type Classification
**Job**: `SubmissionTypeClassificationJob`
- Use RubyLLM with OpenAI API to classify submission type
- Analyze URL pattern, content, metadata
- Set `submission_type` enum
- Use RubyLLM Tools for structured classification

#### 5. Tool Detection & Creation
**Job**: `SubmissionToolDetectionJob`
- Use RubyLLM with OpenAI API to detect if submission references a tool
- Analyze content, metadata, submission type, URL
- Extract tool name(s) mentioned in the submission
- For each detected tool:
  - Check if Tool exists (by name matching)
  - If Tool doesn't exist: Create new Tool instance automatically
  - Link submission to Tool via `submission.tool_id`
- Store detected tools in `metadata['detected_tools']`

**Example:**
- User submits article: "Getting Started with React Hooks"
- System detects "React" as a tool
- Checks if "React" tool exists
- If not, creates Tool(name: "React")
- Links article submission to React tool

#### 6. Tag Generation
**Job**: `SubmissionTagGenerationJob`
- Use RubyLLM with OpenAI API to generate relevant tags
- Analyze content, metadata, submission type
- Generate 3-10 relevant tags
- Match to existing tags or suggest new tags
- Associate tags with submission

#### 7. Content Summarization
**Job**: `SubmissionSummarizationJob`
- Use RubyLLM with OpenAI API to generate summary
- Analyze scraped content
- Generate concise summary (2-3 sentences)
- Store in `metadata['summary']`

#### 8. Embedding Generation
**Job**: `SubmissionEmbeddingGenerationJob`
- Generate vector embeddings for submission content
- Use `RubyLLM.embed` (see https://rubyllm.com/embeddings/)
- Default model: `text-embedding-3-small` (1536 dimensions) or `text-embedding-3-large` (3072 dimensions)
- Input: Combined text from title, description, author_note, scraped content, tags
- Store embeddings in `embedding` column (PostgreSQL vector type with pgvector extension)
- Use batch embedding for multiple texts: `RubyLLM.embed([text1, text2])` (more efficient)
- **Critical for semantic search and RAG**
- Calculate cosine similarity for finding similar submissions

#### 9. Related Content Discovery
**Job**: `SubmissionRelationshipDiscoveryJob`
- Use embeddings for semantic similarity search (vector similarity)
- Use RubyLLM with OpenAI API for relationship analysis
- Analyze content, tags, categories, embeddings
- Find semantically similar submissions using cosine similarity
- Create relationships (new model: `SubmissionRelationship`)
- Example: Article about React exploit → connect to React tool via embedding similarity

### RubyLLM Implementation

**Required RubyLLM Features:**
- **Chat/Conversations**: For content analysis and classification
- **Tools**: For structured output (type classification, category assignment)
- **Schema Validation**: For ensuring structured responses
- **Async Execution**: For parallel processing of multiple checks

**RubyLLM Tools Needed:**
1. **Content Safety Tool**: Classify content as safe/unsafe with reason (Stage 2)
2. **Type Classification Tool**: Classify submission type with confidence
3. **Tool Detection Tool**: Detect and extract tool names from content
4. **Tag Generation Tool**: Generate relevant tags
5. **Relationship Discovery Tool**: Find related submissions (future phase)

**Documentation References:**
- Main: https://rubyllm.com/
- Rails Integration: https://rubyllm.com/rails/ - For ActiveRecord persistence, Hotwire streaming, and Rails-specific patterns
- Tools: https://rubyllm.com/tools/
- Async: https://rubyllm.com/async/
- Schema: Use `RubyLLM::Schema` for structured output

### Background Jobs Architecture

**Job Organization:**
```
app/jobs/
  submission_processing/
    submission_duplicate_check_job.rb          # Phase 1: Fast, synchronous check
    submission_safety_check_job.rb             # Phase 1: Two-stage safety validation
    submission_metadata_extraction_job.rb      # Phase 2: Scraping (can run in parallel with safety)
    submission_type_classification_job.rb      # Phase 3: Requires metadata
    submission_tool_detection_job.rb          # Phase 3: Requires metadata, creates Tools
    submission_tag_generation_job.rb           # Phase 3: Requires metadata
    submission_summarization_job.rb            # Phase 3: Requires scraped content (future phase)
    submission_embedding_generation_job.rb      # Phase 4: Requires all metadata (future phase)
    submission_relationship_discovery_job.rb   # Phase 5: Requires embedding (future phase)
  submission_processing_job.rb  # Orchestrator job
```

**Processing Pipeline Dependencies:**

**Phase 1: Immediate Checks (Parallel)**
- Duplicate check (fast, synchronous - blocks if duplicate) - **WORKING**
- Safety check (two-stage: programmatic + LLM) - **WORKING**

**Phase 2: Content Extraction (Parallel with Phase 1)**
- Metadata extraction (scraping: title, description, images) - **WORKING**

**Phase 3: Classification & Enrichment (Requires Phase 2)**
- Type classification (needs metadata) - **WORKING** (Phase 1)
- Tool detection & creation (needs metadata) - **WORKING** (Phase 1)
- Tag generation (needs metadata) - **WORKING** (Phase 1)
- Summarization (needs scraped content) - **STUB** (Phase 1, implement in Phase 2)

**Phase 4: Embedding Generation (Requires Phase 3)**
- Embedding generation (needs all metadata, tags) - **WORKING** (Phase 1)

**Phase 5: Relationship Discovery (Requires Phase 4)**
- Relationship discovery (needs embeddings + all metadata) - **STUB** (Phase 1, implement in Phase 2)

**Note:** In Phase 1, the complete pipeline structure exists, but `SummarizationJob` and `RelationshipDiscoveryJob` are stubs (placeholders that log or return early). All other jobs are fully working.

**Orchestrator Pattern:**
- `SubmissionProcessingJob` enqueues jobs in phases
- Phase 1 jobs run first (duplicate check blocks if duplicate found)
- Phase 2-3 jobs can run in parallel after Phase 1
- Phase 4 waits for Phase 3 completion
- Phase 5 waits for Phase 4 completion
- Use `Async` gem for parallel execution within phases
- Jobs update submission status as they complete
- Final job updates `status: :completed` when all succeed

**Error Handling:**
- Each job should be idempotent
- Use `retry_on` for transient failures
- Use `discard_on` for permanent failures
- Log errors with context
- Update submission `status: :failed` on permanent failure

## Safety & Validation

### Duplicate Prevention

**Strategy:**
- Normalize URLs before comparison:
  - Remove trailing slashes
  - Remove query parameters (or keep specific ones)
  - Remove fragments
  - Convert to lowercase
  - Remove `www.` prefix
- Store normalized URL in `normalized_url` column
- Add unique index on `normalized_url`
- Check on submission creation (synchronous check before async processing)

**Implementation:**
```ruby
# In Submission model
validates :normalized_url, uniqueness: true
before_validation :normalize_url

def normalize_url
  return if submission_url.blank?
  uri = URI.parse(submission_url)
  uri.host = uri.host&.sub(/\Awww\./, "")
  uri.fragment = nil
  uri.query = nil  # Or keep specific query params
  self.normalized_url = uri.to_s.downcase
end
```

### Content Safety

**Safety Checks:**
1. **Content Moderation**: Use RubyLLM to analyze scraped content
2. **URL Pattern Analysis**: Check URL against known unsafe domains
3. **Content Type Validation**: Ensure content is related to software/tech

**RubyLLM Safety Tool:**
- Input: Scraped content, URL, metadata
- Output: `{ safe: boolean, reason: string, confidence: float }`
- Use GPT-4o for safety checks (more reliable)

**Rejection Criteria:**
- Pornography or explicit sexual content
- Graphic violence or gore
- Completely unrelated to software/technology
- Malicious content (phishing, malware, etc.)
- Spam or low-quality content

**User Experience:**
- Show clear rejection message
- Allow user to appeal (future feature)
- Log all rejections for review

## Enhanced Search & Discovery

### Current Search Limitations

**Existing Search:**
- Basic ILIKE queries on `tool_name`, `tool_description`, `tags.tag_name`
- No semantic understanding
- No full-text search capabilities
- No ranking by relevance
- Limited to exact/partial string matches

**Problems:**
- "React" won't find "React.js" or "ReactJS" unless exact match
- "JavaScript framework" won't find "JS framework" or related concepts
- No understanding of synonyms or related terms
- No semantic similarity (e.g., "frontend" vs "client-side")

### Search Strategy Options

#### PostgreSQL Full-Text Search with pg_search (Selected for Phase 1)

**Decision:** Use PostgreSQL full-text search with `pg_search` gem for Phase 1.

**Pros:**
- No additional infrastructure
- Already using PostgreSQL
- Good enough for Phase 1 and beyond
- Free (no additional cost)
- Easier to implement
- `pg_search` gem provides convenient Rails integration
- Can combine with semantic search via embeddings later

**Cons:**
- Less powerful than Elasticsearch for very advanced features
- Limited relevance scoring (but sufficient for most use cases)
- No built-in faceting (but can be implemented with ActiveRecord)

**Implementation:**
- Use `pg_search` gem
- Add full-text search indexes (GIN indexes)
- Use `pg_search` multisearch or scoped search
- Search across submissions, tools, tags
- Combine with semantic search via embeddings in future phases

**Future Consideration:** Elasticsearch can be added later if needed for:
- Very large scale (>100K submissions)
- Advanced faceting and aggregations
- Complex relevance scoring requirements
- Auto-complete and suggestions at scale

### Semantic Search with Embeddings

**Strategy:**
- Generate embeddings for all submissions (see Embedding Generation job)
- Store embeddings in PostgreSQL using `pgvector` extension OR in Redis
- Use cosine similarity for semantic search
- Combine keyword search (PostgreSQL full-text) with semantic search (embeddings)

**Implementation:**
```ruby
# Using pgvector (PostgreSQL extension)
# Add to Gemfile: gem 'pgvector'
# Migration: enable_extension 'vector'
# Add column: t.vector :embedding, limit: 1536  # OpenAI embedding dimension

# Search query combining full-text and semantic
def semantic_search(query, limit: 10)
  query_embedding = generate_embedding(query)
  
  # Combine full-text search with semantic similarity
  Submission
    .where("embedding <=> ? < 0.8", query_embedding)  # Cosine distance
    .or(Submission.where("to_tsvector('english', tool_name || ' ' || tool_description) @@ plainto_tsquery('english', ?)", query))
    .order("embedding <=> ?", query_embedding)
    .limit(limit)
end
```

### RAG (Retrieval-Augmented Generation) Strategy

**Use Cases:**
1. **Enhanced Search Results**: Use RAG to generate contextual summaries of search results
2. **Submission Recommendations**: Generate personalized recommendations based on user's followed content
3. **Content Summarization**: Use RAG to create better summaries by retrieving related context
4. **Question Answering**: Allow users to ask questions about submissions and get answers using RAG

**Implementation:**
- Store submission embeddings in vector database (PostgreSQL pgvector or Redis)
- When user searches, retrieve top-K similar submissions using embeddings
- Use retrieved submissions as context for RubyLLM to generate:
  - Enhanced search result descriptions
  - Personalized recommendations
  - Answer questions about submissions

**RAG Pipeline:**
1. User query → Generate query embedding
2. Vector similarity search → Retrieve top-K relevant submissions
3. Combine retrieved submissions with query → Send to RubyLLM
4. RubyLLM generates response using retrieved context
5. Return enhanced results to user

## Related Content Discovery

### Relationship Model

**New Model: `SubmissionRelationship`**
- `submission_id` (references :submission)
- `related_submission_id` (references :submission)
- `relationship_type` enum (related_to, mentions, similar_to, part_of)
- `strength` (float, 0.0-1.0) - confidence score (from embedding similarity or LLM)
- `created_by` enum (user, system, llm, embedding)

**Associations:**
```ruby
# Submission model
has_many :submission_relationships, dependent: :destroy
has_many :related_submissions, through: :submission_relationships
has_many :inverse_relationships, class_name: "SubmissionRelationship", foreign_key: :related_submission_id
has_many :inverse_related_submissions, through: :inverse_relationships, source: :submission
```

### Discovery Strategy

**Hybrid Approach: Embeddings + RubyLLM**

**Step 1: Embedding-Based Discovery (Fast, Scalable)**
1. Generate embedding for new submission
2. Use vector similarity search to find top-K similar submissions (cosine similarity)
3. Candidates with similarity > 0.7 are potential relationships
4. Store as `created_by: :embedding`

**Step 2: RubyLLM Relationship Analysis (Precise, Contextual)**
1. For embedding candidates, use RubyLLM to analyze relationship type
2. RubyLLM determines: `related_to`, `mentions`, `similar_to`, `part_of`
3. RubyLLM provides reasoning and confidence score
4. Store as `created_by: :llm`

**Step 3: User-Generated Relationships**
- Allow users to manually create relationships
- Store as `created_by: :user`

**Example:**
- User submits article: "React 18 Security Vulnerability Exploit"
- Embedding similarity finds "React" tool submission (similarity: 0.85)
- RubyLLM analyzes: "Article mentions React tool, discusses security vulnerability"
- Creates relationship: `{ type: :mentions, strength: 0.9, created_by: :llm }`
- Displays relationship in UI

**UI Display:**
- Show "Related Content" section on submission show page
- Display related submissions with relationship type and strength
- Show relationship source (embedding, LLM, or user-created)
- Allow users to navigate between related content
- Allow users to create/edit/delete relationships

## Notification System Integration

### Current State

**Follow System:**
- Polymorphic `Follow` model exists
- Users can follow: `Tool`, `List`, `Tag`, `User`
- No notification system yet (planned)

### Notification System: Noticed Gem

**Decision:** Use the [Noticed gem](https://github.com/excid3/noticed) for notifications.

**Why Noticed:**
- Mature, well-maintained Rails notification gem
- Supports multiple delivery channels (database, email, Action Cable, etc.)
- Easy to extend with custom delivery methods
- Works well with Turbo Streams for real-time updates
- Active community and good documentation

**Notification Requirements:**

**When to Notify:**
1. **New Submission on Followed Tag**: User follows "React" tag → notify when new React submission is created
2. **New Submission on Followed Tool**: User follows "React" tool → notify when new submission about React is created
3. **New Submission from Followed User**: User follows a user → notify when they create new submission
4. **Update to Followed Submission**: User follows a submission → notify when:
   - Submission status changes (processing → completed)
   - New comments added
   - Submission is updated (description, tags, etc.)
5. **Processing Complete**: Notify submitter when their submission processing completes

**Implementation:**
- Install `noticed` gem
- Create notification classes (e.g., `NewSubmissionNotification`, `SubmissionUpdatedNotification`)
- Use Noticed's database delivery for persistence
- Use Noticed's Action Cable delivery for real-time updates
- Integrate with Turbo Streams for UI updates

**Integration Points:**
- After submission processing completes → notify followers
- After new submission created → notify users following related tags/tools/users
- Use Turbo Streams for real-time notification updates

**Implementation Notes:**
- Defer notification system to Phase 2+ (after basic submission processing)
- Use Noticed's flexible notification system for future notification types
- Store notification preferences per user (what they want to be notified about)

## Implementation Phases

### Phase 1: Foundation with Complete Pipeline Structure (Week 1-3)
**Goal:** Migrate to Submission model, establish complete processing pipeline (with stubs), implement working classification/tagging, simple embeddings/RAG, and improved search

**Priority Order:**
1. **Most Important**: Migration to Submission, Classification & Tagging, Search
2. **Crucial**: Embeddings & RAG (simple but working)
3. **Important**: Complete pipeline structure (some jobs can be stubs)
4. **Least Important**: Notifications (minimal or deferred)

#### 1. Migration to Submission Model (Week 1)
- [ ] Create `Submission` model (keep `Tool` as top-level entity)
- [ ] Remove `belongs_to :user` from `Tool` model (tools are community-owned)
- [ ] Add `submission_type` enum (include `post` type for future, but Phase 1 focuses on links)
- [ ] Add `status` enum (pending, processing, completed, failed, rejected)
- [ ] Add `metadata` JSONB column
- [ ] Add `normalized_url` column with unique index (nullable for future text-only posts)
- [ ] Add `tool_id` foreign key (submission belongs_to tool, optional)
- [ ] Add `embedding` vector column (for pgvector) - prepare for embeddings
- [ ] Migrate existing `Tool` data: 
  - Keep existing tools as community resources (remove user ownership)
  - Decide which user-created tools should become submissions vs remain as tools
- [ ] Update all controllers, views, routes from `tools` to `submissions`
- [ ] Update user dashboard: Change "My Tools" to "My Submissions"
- [ ] Update associations (comments, tags, lists, follows)
- [ ] Create submission form (URL + author_note) - Phase 1: links only
- [ ] Create submission controller (new, create, show, index, edit, update, destroy)
- [ ] Update routes
- [ ] Submission listing and display
- [ ] Update tests

#### 2. Complete Processing Pipeline Structure (Week 1-2)
**Goal:** All jobs exist, some are stubs, but pipeline is complete and working

- [ ] Create `SubmissionProcessingJob` orchestrator
- [ ] Create all processing jobs (even if stubs):
  - [ ] `SubmissionDuplicateCheckJob` - **Working** (synchronous, simple)
  - [ ] `SubmissionSafetyCheckJob` - **Working** (two-stage: programmatic + basic LLM)
  - [ ] `SubmissionMetadataExtractionJob` - **Working** (basic: title, description, images)
  - [ ] `SubmissionTypeClassificationJob` - **Working** (RubyLLM classification)
  - [ ] `SubmissionToolDetectionJob` - **Working** (detect and create tools)
  - [ ] `SubmissionTagGenerationJob` - **Working** (RubyLLM tag generation)
  - [ ] `SubmissionSummarizationJob` - **Stub** (placeholder for future)
  - [ ] `SubmissionEmbeddingGenerationJob` - **Working** (simple embedding generation)
  - [ ] `SubmissionRelationshipDiscoveryJob` - **Stub** (placeholder for future)
- [ ] Set up job dependencies and execution order
- [ ] Create job status tracking
- [ ] Add Turbo Streams for real-time processing updates
- [ ] Error handling and retry logic

#### 3. Classification & Tagging (Week 2) - **MOST IMPORTANT**
- [ ] Install RubyLLM Rails integration (follow https://rubyllm.com/rails/)
- [ ] Set up RubyLLM configuration
- [ ] Create RubyLLM Tools:
  - [ ] `SubmissionTypeClassificationTool` - Classify submission type
  - [ ] `SubmissionTagGenerationTool` - Generate relevant tags
  - [ ] `SubmissionToolDetectionTool` - Detect tools mentioned
- [ ] Implement `SubmissionTypeClassificationJob` (working, not stub)
- [ ] Implement `SubmissionTagGenerationJob` (working, not stub)
- [ ] Implement `SubmissionToolDetectionJob` (working, not stub)
- [ ] Match generated tags to existing tags or create new ones
- [ ] Associate tags with submissions
- [ ] Test classification accuracy
- [ ] Test tag generation quality

#### 4. Simple Embeddings & RAG (Week 2-3) - **CRUCIAL**
- [ ] Install `pgvector` extension
- [ ] Add `embedding` column to submissions table (vector type)
- [ ] Set up OpenAI embeddings API integration
- [ ] Implement `SubmissionEmbeddingGenerationJob`:
  - [ ] Generate embeddings for submission content (title + description + author_note + scraped content)
  - [ ] Store embeddings in database
  - [ ] Handle errors gracefully
- [ ] Create simple RAG service:
  - [ ] Generate query embedding for user search
  - [ ] Find top-K similar submissions using vector similarity (cosine similarity)
  - [ ] Use retrieved submissions as context for RubyLLM
  - [ ] Generate enhanced search results with context
- [ ] Integrate RAG into search flow
- [ ] Test embedding generation
- [ ] Test RAG search results quality

#### 5. Improved Search (Week 2-3) - **MOST IMPORTANT**
- [ ] Install `pg_search` gem
- [ ] Add `pg_search` multisearch to Submission and Tool models
- [ ] Create search indexes (GIN indexes for full-text search)
- [ ] Create search service that combines:
  - [ ] PostgreSQL full-text search (`pg_search`)
  - [ ] Vector similarity search (embeddings)
  - [ ] Hybrid ranking (combine both results)
- [ ] Update search controller to use new search service
- [ ] Improve search UI:
  - [ ] Show search results with relevance
  - [ ] Display submission type badges
  - [ ] Show tags and tool associations
- [ ] Test search performance and accuracy
- [ ] Optimize search queries

#### 6. Basic Notifications (Week 3) - **LEAST IMPORTANT**
- [ ] Install `noticed` gem (or defer to Phase 2)
- [ ] Create basic notification for submission processing complete
- [ ] Minimal notification UI (or defer to Phase 2)
- [ ] **Note:** Can be minimal or deferred if time is limited

#### 7. Additional Phase 1 Features
- [ ] Two-stage content safety (programmatic check + LLM validation)
- [ ] Duplicate detection with similar link checking
- [ ] Basic metadata extraction (title, description, images from Open Graph)
- [ ] Processing status UI (show status, allow retry on failure)
- [ ] Error handling and user feedback

### Phase 2: Enhanced Processing & Notifications (Week 4-5)
- [ ] Enhance content safety (improve programmatic checks, refine LLM validation)
- [ ] Enhance duplicate detection (improve similar link detection algorithm)
- [ ] Enhance metadata extraction (more comprehensive scraping)
- [ ] Implement `SubmissionSummarizationJob` (was stub in Phase 1)
- [ ] Implement `SubmissionRelationshipDiscoveryJob` (was stub in Phase 1)
- [ ] Full notification system with Noticed gem
- [ ] Notification preferences per user
- [ ] Real-time notification UI (badge, dropdown, mark as read)
- [ ] Performance optimization

### Phase 3: Advanced Features (Week 6+)
- [ ] Advanced RAG features (multi-step reasoning, better context retrieval)
- [ ] Enhanced relationship discovery (improve similarity algorithms)
- [ ] Advanced search features (faceting, filtering, sorting)
- [ ] Performance optimization (caching, indexing, query optimization)
- [ ] Analytics and monitoring
- [ ] User feedback and improvement loops

### Phase 4: Scale & Polish (Week 7+)
- [ ] Scale embeddings and RAG for large datasets
- [ ] Advanced relationship discovery algorithms
- [ ] Consider Elasticsearch migration if needed
- [ ] Advanced analytics and insights
- [ ] Community features
- [ ] Polish and refinement

## Technical Requirements

### Dependencies

**Existing:**
- RubyLLM (`ruby_llm` gem) - Already in Gemfile
- RubyLLM Schema (`ruby_llm-schema` gem) - Already in Gemfile
- Async gem (`async` gem) - Already in Gemfile
- Active Job (Rails built-in)

**New Dependencies (Phase 1):**
- `pg_search` gem for PostgreSQL full-text search
- `pgvector` gem for vector embeddings (PostgreSQL extension)
- `noticed` gem for notifications (can be minimal in Phase 1)
- HTTP client for web scraping (`httparty`, `faraday`, or `nokogiri`)
- `nokogiri` for HTML parsing and scraping
- `open-uri` or `faraday` for HTTP requests
- URL normalization (custom implementation or URI gem)

### Database Changes

**Migrations Needed (Phase 1):**
1. Create `submissions` table (keep `tools` table as-is)
2. Add `submission_type` enum column
3. Add `status` enum column
4. Add `tool_id` foreign key (belongs_to Tool, optional)
5. Add `metadata` JSONB column
6. Add `normalized_url` string column with unique index
7. Add `duplicate_of_id` foreign key (references submissions)
8. Add `processed_at` datetime column
9. Add `user_id` foreign key (belongs_to User)
10. Add `embedding` vector column (for pgvector embeddings)
11. Enable PostgreSQL extensions:
    - `pg_trgm` (for trigram search)
    - `vector` (for pgvector - embeddings)
12. Add full-text search indexes (GIN indexes on text columns)
13. Add vector similarity indexes (HNSW or IVFFlat for pgvector)
14. Update foreign key references in related tables (comments, tool_tags, list_tools, follows)
15. Migrate existing Tool data (decide which become submissions vs remain tools)

**Future Migrations:**
- Create `submission_relationships` table (when implementing relationships in Phase 2)

### API Integration

**OpenAI API:**
- Use GPT-4o for safety checks and complex analysis
- Use GPT-4o-mini for simple classification tasks
- Configure via environment variables (`OPENAI_API_KEY`)
- Implement rate limiting and error handling
- Cache responses where appropriate

### Performance Considerations

**Async Processing:**
- Use Active Job with background queue adapter (Redis, Sidekiq, or default)
- Process jobs in parallel using `Async` gem
- Set appropriate timeouts for each job
- Implement job prioritization (safety checks first)

**Caching:**
- Cache scraped content to avoid re-scraping
- Cache RubyLLM responses for similar content
- Use Redis for job queue and caching

**Database:**
- Add indexes on `normalized_url`, `submission_type`, `status`, `tool_id`
- Use JSONB indexes on `metadata` for common queries
- Add GIN indexes for full-text search on submission text fields
- Add vector indexes (HNSW or IVFFlat) for embedding similarity search (Phase 1)
- Consider composite indexes for common query patterns (status + submission_type, etc.)
- Index `follows` table for efficient notification queries
- Index `tool_id` for efficient tool-submission lookups

### Error Handling

**Job Failures:**
- Retry transient failures (network errors, rate limits)
- Discard permanent failures (invalid URLs, unreachable content)
- Log all failures with context
- Update submission status appropriately
- Notify user of processing failures

**User Experience:**
- Show processing status in UI
- Display errors clearly
- Allow manual retry of failed processing
- Provide fallback for failed metadata extraction

## UI/UX Considerations

### Submission Form

**Current Form:**
- URL input
- Author note (free text)

**Enhanced Form:**
- URL input (with validation)
- Free text description (optional, helps with classification)
- Preview of submission (if URL can be pre-scraped)
- Processing status indicator

### Submission Show Page

**Current:**
- Tool name, description, URL
- Tags, comments, interactions

**Enhanced:**
- Submission type badge
- Category display
- Related content section
- Processing status (if still processing)
- Rich metadata display (images, summary, etc.)

### Processing Status

**Status Indicators:**
- Pending: "Processing your submission..."
- Processing: "Analyzing content..."
- Completed: "Ready!"
- Failed: "Processing failed - click to retry"
- Rejected: "Submission rejected: [reason]"

**Real-time Updates:**
- Use Turbo Streams to update status as jobs complete
- Show progress for long-running operations
- Update metadata as it becomes available

## Testing Strategy

### Unit Tests
- Model validations and associations
- URL normalization logic
- Duplicate detection logic
- Metadata extraction helpers

### Job Tests
- Each processing job in isolation
- Error handling and retry logic
- Idempotency of jobs

### Integration Tests
- Full submission processing flow
- RubyLLM integration
- Relationship discovery
- Safety checks

### System Tests
- User submits link
- System processes submission
- User sees enriched submission
- User sees related content

## Security Considerations

### API Keys
- Store OpenAI API key in `config/credentials.yml.enc`
- Never expose API keys in logs or responses
- Rotate keys regularly

### Content Safety
- Validate all user input
- Sanitize scraped content before storage
- Rate limit RubyLLM API calls
- Monitor for abuse patterns

### Data Privacy
- Don't store sensitive user data in metadata
- Respect robots.txt when scraping
- Implement scraping rate limits
- Cache scraped content appropriately

## Future Enhancements

### Text-Only Posts (Future Phase)
- **Submissions as Posts**: Allow text-only submissions (like Twitter posts)
- **Post Features**:
  - Users can create text-only posts (no URL required)
  - Posts generate tool associations through text analysis
  - Posts appear on user profiles
  - Posts appear in feeds (when feed system is implemented)
  - Posts can be threaded/replied to
  - Posts can reference tools, submissions, and other users
- **Implementation**: 
  - Add `post` submission type (already in enum)
  - Make `normalized_url` nullable for posts
  - Generate embeddings from post text
  - Use RubyLLM to detect tool mentions in posts
  - Create associations between posts and tools
- **Phase 1**: Focus on link submissions only, posts are future consideration

### Other Future Enhancements
- User appeals for rejected submissions
- Manual moderation queue
- Advanced relationship visualization
- Submission versioning (if URL content changes)
- Bulk submission import
- Submission analytics
- User reputation system
- Community moderation
- Feed system (for posts and submissions)
- User profile pages showing their submissions and posts

## Critical Considerations & Potential Issues

### Issues with Current Proposal

1. **Processing Order Dependency**: Some jobs depend on others (e.g., relationship discovery needs embeddings, which needs metadata). Need to define job dependencies and execution order.

2. **Cost Management**: Multiple RubyLLM API calls per submission can be expensive. Need:
   - Aggressive caching of LLM responses
   - Batch processing where possible
   - Rate limiting per user
   - Cost monitoring and alerts

3. **Scraping Reliability**: Web scraping is unreliable:
   - Sites may block scrapers
   - Content may be behind authentication
   - JavaScript-rendered content won't be scraped
   - Need fallback strategies (use Open Graph, Twitter Cards, etc.)

4. **Embedding Storage**: 
   - PostgreSQL pgvector: Good for small-medium scale, but may need Elasticsearch later
   - Redis: Fast but may lose data, need persistence strategy
   - Consider hybrid: Store in PostgreSQL, cache in Redis

5. **Search Performance**: 
   - Vector similarity search can be slow on large datasets
   - Need proper indexing (HNSW for pgvector)
   - May need to limit search scope (by category, type, etc.)
   - Consider caching search results

6. **Notification Volume**: 
   - Users following many tags/users could get notification spam
   - Need notification preferences and batching
   - Consider digest emails instead of real-time for some events

7. **Data Consistency**: 
   - Multiple async jobs updating same record → race conditions
   - Need proper locking or optimistic locking
   - Use database transactions where appropriate

8. **Error Recovery**: 
   - What if embedding generation fails but other jobs succeed?
   - What if relationship discovery fails?
   - Need partial success handling
   - Allow manual retry of failed jobs

### Missing Crucial Considerations

1. **Rate Limiting**: 
   - Limit submissions per user per day/hour
   - Prevent abuse and spam
   - Implement in controller before processing

2. **Content Moderation Queue**: 
   - Some submissions may need manual review
   - Add `needs_review` flag
   - Admin interface for moderation

3. **Submission Versioning**: 
   - URLs may change content over time
   - Should we re-scrape periodically?
   - Track content changes and notify followers?

4. **User Feedback Loop**: 
   - Allow users to report incorrect classifications
   - Allow users to suggest better tags/categories
   - Use feedback to improve LLM prompts

5. **Analytics & Monitoring**: 
   - Track processing times per job
   - Track LLM API costs per submission
   - Monitor error rates
   - Track search performance

6. **Internationalization**: 
   - Scraped content may be in different languages
   - LLM classification should handle multiple languages
   - Search should support multiple languages

7. **Accessibility**: 
   - Scraped images need alt text
   - Generated content should be accessible
   - Search should work with screen readers

8. **Privacy & GDPR**: 
   - Scraped content may contain personal data
   - Need data retention policies
   - Allow users to delete their submissions and associated data

9. **Backfill Strategy**: 
   - How to process existing tools/submissions?
   - Need backfill jobs for:
     - Embedding generation
     - Relationship discovery
     - Metadata extraction
   - Should run in background, not block new submissions

10. **Testing Strategy for LLM**: 
    - How to test RubyLLM integration?
    - Mock LLM responses in tests
    - Use VCR for recording LLM API calls
    - Test with various content types

## Open Questions

1. **Naming**: Should we rename "Tool" to "Submission" or keep both?
   - **Decision**: Keep both - Tools are top-level entities (ideas/topics), Submissions are user-submitted links about tools
   - Tools: "React", "Git", "Docker" (top-level entities users follow)
   - Submissions: Articles, guides, repos about those tools
   - If submission references a tool that doesn't exist, create both the submission and the tool

2. **Backward Compatibility**: How to handle existing tools?
   - **Recommendation**: Keep existing `Tool` model as-is (tools are top-level entities)
   - Create new `Submission` model for user-submitted links
   - Existing tools remain as tools, new submissions link to tools
   - No migration needed - tools and submissions coexist

3. **Scraping Rate Limits**: How to handle rate limits when scraping?
   - **Recommendation**: Implement exponential backoff, cache results, respect robots.txt
   - Use Open Graph/Twitter Cards as primary source, fallback to scraping

4. **RubyLLM Costs**: How to manage OpenAI API costs?
   - **Recommendation**: Use GPT-4o-mini for simple tasks, GPT-4o for complex analysis
   - Cache responses aggressively
   - Implement rate limiting per user
   - Monitor costs and set budgets

5. **Relationship Discovery Performance**: How to scale relationship discovery?
   - **Recommendation**: Use embeddings for fast similarity search, LLM for relationship type analysis
   - Cache relationships
   - Limit relationship discovery to recent submissions initially

6. **Elasticsearch vs PostgreSQL Full-Text Search**: When to migrate?
   - **Recommendation**: Start with PostgreSQL full-text search for MVP
   - Migrate to Elasticsearch when:
     - Search becomes slow (>100ms)
     - Need advanced features (faceting, aggregations)
     - Have >100K submissions
     - Have budget for Elasticsearch hosting

7. **Embedding Storage**: PostgreSQL pgvector vs Redis?
   - **Recommendation**: Start with PostgreSQL pgvector (persistent, integrated)
   - Use Redis for caching search results and embeddings
   - Consider Elasticsearch if migrating for search anyway

8. **Notification Frequency**: How to prevent notification spam?
   - **Recommendation**: 
     - Batch notifications (digest for non-urgent)
     - User preferences (what to be notified about)
     - Rate limit notifications per user
     - Allow users to mute specific tags/users

## References

- RubyLLM Documentation: https://rubyllm.com/
- RubyLLM Rails Integration: https://rubyllm.com/rails/ - For ActiveRecord persistence, Hotwire streaming, and Rails-specific patterns
- RubyLLM Tools: https://rubyllm.com/tools/
- RubyLLM Async: https://rubyllm.com/async/
- Rails Active Job: https://guides.rubyonrails.org/active_job_basics.html
- PostgreSQL Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
- pg_search Gem: https://github.com/Casecommons/pg_search
- Noticed Gem: https://github.com/excid3/noticed - For notifications
- pgvector Extension: https://github.com/pgvector/pgvector (future phase)
- OpenAI Embeddings API: https://platform.openai.com/docs/guides/embeddings (future phase)
- Current Specification: `docs/SPECIFICATION.md`
- Follow System: `app/models/follow.rb` (polymorphic follows for Tool, List, Tag, User)


# Phase 1 Implementation Plan

**Status**: Planning  
**Duration**: 3 weeks  
**Last Updated**: 2025-12-11  
**Related**: `docs/SUBMISSION_PROCESS_IMPROVEMENT.md`

## Overview

Phase 1 establishes the foundation for the submission system by:
1. Migrating from Tool-centric to Submission-centric model
2. Implementing complete processing pipeline structure (with some stubs)
3. Building working classification and tagging with RubyLLM
4. Adding simple embeddings and RAG for search
5. Improving search with PostgreSQL full-text search
6. Setting up minimal notifications

## Prerequisites

Before starting Phase 1, ensure:
- [ ] Ruby 3.3.5 installed
- [ ] PostgreSQL 14+ running locally
- [ ] Redis running locally (for Active Job)
- [ ] OpenAI API key available (`OPENAI_API_KEY`)
- [ ] Current codebase is on a feature branch
- [ ] All existing tests pass
- [ ] Database backup created

## Week 1: Migration & Foundation

### Day 1-2: Database Migration & Model Setup

#### Step 1.1: Create Submission Model Migration
**File**: `db/migrate/YYYYMMDDHHMMSS_create_submissions.rb`

**Tasks:**
- [ ] Create `submissions` table with columns:
  - `user_id` (references users, null: false)
  - `tool_id` (references tools, null: true, optional)
  - `submission_type` (integer, enum)
  - `status` (integer, enum, default: 0)
  - `submission_url` (string, null: true) - nullable for future posts
  - `normalized_url` (string, null: true, unique index)
  - `author_note` (text)
  - `submission_name` (string) - extracted/derived name
  - `submission_description` (text) - extracted description
  - `metadata` (jsonb) - store extracted data
  - `duplicate_of_id` (references submissions, null: true)
  - `processed_at` (datetime, null: true)
  - `timestamps`
- [ ] Add indexes:
  - `index_submissions_on_user_id`
  - `index_submissions_on_tool_id`
  - `index_submissions_on_normalized_url` (unique)
  - `index_submissions_on_status`
  - `index_submissions_on_submission_type`
  - GIN index on `metadata` for JSONB queries
- [ ] Add foreign key constraints

**Enum Definitions:**
```ruby
# submission_type enum
enum submission_type: {
  article: 0,
  guide: 1,
  documentation: 2,
  github_repo: 3,
  social_post: 4,
  code_snippet: 5,
  website: 6,
  video: 7,
  podcast: 8,
  post: 9,  # Future feature
  other: 10
}

# status enum
enum status: {
  pending: 0,
  processing: 1,
  completed: 2,
  failed: 3,
  rejected: 4
}
```

#### Step 1.2: Update Tool Model
**File**: `app/models/tool.rb`

**Tasks:**
- [ ] Remove `belongs_to :user` association
- [ ] Add `has_many :submissions` association
- [ ] Add validation to ensure tools are community-owned (no user ownership)
- [ ] Update scopes if needed
- [ ] Keep all existing functionality (tags, comments, lists, follows)

#### Step 1.3: Create Submission Model
**File**: `app/models/submission.rb`

**Tasks:**
- [ ] Create model with associations:
  - `belongs_to :user`
  - `belongs_to :tool, optional: true`
  - `has_many :comments, dependent: :destroy`
  - `has_many :submission_tags, dependent: :destroy`
  - `has_many :tags, through: :submission_tags`
  - `has_many :list_submissions, dependent: :destroy`
  - `has_many :lists, through: :list_submissions`
  - `has_many :follows, as: :followable, dependent: :destroy`
  - `has_many :followers, through: :follows, source: :user`
- [ ] Add enums for `submission_type` and `status`
- [ ] Add validations:
  - `submission_url` format (if present)
  - `normalized_url` uniqueness (if present)
  - `user_id` presence
- [ ] Add `normalize_url` method (before_validation callback)
- [ ] Add scopes: `pending`, `processing`, `completed`, `failed`, `rejected`, `recent`
- [ ] Add helper methods: `processing?`, `completed?`, `failed?`, `rejected?`

#### Step 1.4: Create SubmissionTag Join Model
**File**: `db/migrate/YYYYMMDDHHMMSS_create_submission_tags.rb`
**File**: `app/models/submission_tag.rb`

**Tasks:**
- [ ] Create `submission_tags` join table:
  - `submission_id` (references submissions)
  - `tag_id` (references tags)
  - `timestamps`
  - Unique index on `[submission_id, tag_id]`
- [ ] Create `SubmissionTag` model with associations
- [ ] Update `Tag` model to add `has_many :submission_tags` and `has_many :submissions, through: :submission_tags`

#### Step 1.5: Create ListSubmission Join Model
**File**: `db/migrate/YYYYMMDDHHMMSS_create_list_submissions.rb`
**File**: `app/models/list_submission.rb`

**Tasks:**
- [ ] Create `list_submissions` join table:
  - `list_id` (references lists)
  - `submission_id` (references submissions)
  - `timestamps`
  - Unique index on `[list_id, submission_id]`
- [ ] Create `ListSubmission` model with associations
- [ ] Update `List` model to add `has_many :list_submissions` and `has_many :submissions, through: :list_submissions`

#### Step 1.6: Update Comment Model
**File**: `app/models/comment.rb`

**Tasks:**
- [ ] Change `belongs_to :tool` to polymorphic `belongs_to :commentable, polymorphic: true`
- [ ] Update migration to add `commentable_type` and `commentable_id` columns
- [ ] Update `Tool` model to add `has_many :comments, as: :commentable`
- [ ] Update `Submission` model to add `has_many :comments, as: :commentable`
- [ ] Update all comment-related code to use `commentable` instead of `tool`

#### Step 1.7: Migrate Existing Data
**File**: `db/migrate/YYYYMMDDHHMMSS_migrate_tools_to_submissions.rb`

**Tasks:**
- [ ] Create data migration script:
  - For each existing Tool:
    - Create Submission with `submission_type: :other` (or detect type)
    - Copy `tool_url` to `submission_url`
    - Copy `tool_name` to `submission_name`
    - Copy `tool_description` to `submission_description`
    - Copy `author_note`
    - Set `user_id` from tool's user
    - Set `status: :completed` (already processed)
    - Link tags via SubmissionTag
    - Link lists via ListSubmission
    - Migrate comments to use polymorphic association
  - Keep Tool records (they become community resources)
  - Remove user ownership from tools
- [ ] Test migration on development database
- [ ] Create rollback script if needed

#### Step 1.8: Run Migrations
**Tasks:**
- [ ] Run `rails db:migrate` on development
- [ ] Verify all tables created correctly
- [ ] Verify indexes created
- [ ] Test data migration
- [ ] Run `rails db:migrate` on test database
- [ ] Update `db/schema.rb`

### Day 3-4: Controllers & Routes

#### Step 1.9: Create Submissions Controller
**File**: `app/controllers/submissions_controller.rb`

**Tasks:**
- [ ] Create controller with actions:
  - `index` - list all submissions (with filtering)
  - `show` - show single submission
  - `new` - new submission form
  - `create` - create submission and queue processing
  - `edit` - edit submission (owner only)
  - `update` - update submission (owner only)
  - `destroy` - delete submission (owner only)
- [ ] Add before_action filters:
  - `set_submission` for show/edit/update/destroy
  - `authorize_owner!` for edit/update/destroy
- [ ] Implement strong parameters
- [ ] Handle Turbo Stream responses
- [ ] Add error handling

#### Step 1.10: Update Routes
**File**: `config/routes.rb`

**Tasks:**
- [ ] Add `resources :submissions` route
- [ ] Add nested routes for comments (polymorphic)
- [ ] Add member routes:
  - `POST /submissions/:id/add_tag`
  - `DELETE /submissions/:id/remove_tag`
  - `POST /submissions/:id/upvote`
  - `POST /submissions/:id/favorite`
  - `POST /submissions/:id/follow`
- [ ] Keep `resources :tools` route (for viewing tools)
- [ ] Update any tool-related routes that should be submission-related

#### Step 1.11: Update Application Controller
**File**: `app/controllers/application_controller.rb`

**Tasks:**
- [ ] Update any tool-related helper methods
- [ ] Ensure authentication works for submissions
- [ ] Update any shared controller logic

### Day 5: Views & Forms

#### Step 1.12: Create Submission Views
**Files**: 
- `app/views/submissions/index.html.erb`
- `app/views/submissions/show.html.erb`
- `app/views/submissions/new.html.erb`
- `app/views/submissions/edit.html.erb`
- `app/views/submissions/_form.html.erb`
- `app/views/submissions/_submission_card.html.erb`

**Tasks:**
- [ ] Create index view with submission cards
- [ ] Create show view with submission details, tags, comments
- [ ] Create new/edit forms (URL + author_note)
- [ ] Create submission card partial (reusable)
- [ ] Add Turbo Stream partials for real-time updates
- [ ] Add i18n translations
- [ ] Style with Bootstrap (consistent with design system)
- [ ] Make responsive (mobile-first)

#### Step 1.13: Update User Dashboard
**File**: `app/views/profiles/show.html.erb` or similar

**Tasks:**
- [ ] Change "My Tools" to "My Submissions"
- [ ] Update to show user's submissions
- [ ] Add link to create new submission
- [ ] Update styling

#### Step 1.14: Update Navigation
**File**: `app/views/shared/_navbar.html.erb`

**Tasks:**
- [ ] Update "Tools" link to "Submissions" (or keep both)
- [ ] Add "New Submission" link
- [ ] Update active state logic

### Day 6-7: Testing & Fixes

#### Step 1.15: Update Tests
**Files**: 
- `test/models/submission_test.rb`
- `test/controllers/submissions_controller_test.rb`
- `test/system/submissions_test.rb`

**Tasks:**
- [ ] Create Submission model tests:
  - Validations
  - Associations
  - Scopes
  - Helper methods
- [ ] Create SubmissionsController tests:
  - All actions
  - Authorization
  - Strong parameters
- [ ] Create system tests:
  - Create submission flow
  - View submission
  - Edit submission
  - Delete submission
- [ ] Update existing tests that reference tools
- [ ] Run all tests and fix failures
- [ ] Ensure test coverage is adequate

## Week 2: Processing Pipeline & RubyLLM Integration

### Day 8-9: Processing Pipeline Structure

#### Step 2.1: Install Dependencies
**File**: `Gemfile`

**Tasks:**
- [ ] Add `pg_search` gem
- [ ] Add `pgvector` gem (for embeddings)
- [ ] Add `nokogiri` gem (for HTML parsing)
- [ ] Add `faraday` or `httparty` gem (for HTTP requests)
- [ ] Add `noticed` gem (for notifications, minimal in Phase 1)
- [ ] Run `bundle install`

#### Step 2.2: Set Up PostgreSQL Extensions
**File**: `db/migrate/YYYYMMDDHHMMSS_enable_postgres_extensions.rb`

**Tasks:**
- [ ] Enable `pg_trgm` extension (for trigram search)
- [ ] Enable `vector` extension (for pgvector)
- [ ] Add full-text search indexes on submission text fields
- [ ] Test extensions are working

#### Step 2.3: Create Submission Processing Orchestrator Job
**File**: `app/jobs/submission_processing_job.rb`

**Tasks:**
- [ ] Create orchestrator job that:
  - Enqueues all processing jobs in correct order
  - Handles job dependencies
  - Updates submission status
  - Handles errors and retries
- [ ] Implement phase-based job execution:
  - Phase 1: Duplicate check, Safety check (parallel)
  - Phase 2: Metadata extraction (after Phase 1)
  - Phase 3: Classification, Tool detection, Tag generation (after Phase 2)
  - Phase 4: Embedding generation (after Phase 3)
  - Phase 5: Relationship discovery (stub, after Phase 4)
- [ ] Add error handling and logging
- [ ] Add Turbo Stream broadcasts for status updates

#### Step 2.4: Create Duplicate Check Job
**File**: `app/jobs/submission_processing/submission_duplicate_check_job.rb`

**Tasks:**
- [ ] Implement duplicate detection:
  - Normalize URL
  - Check for exact duplicates
  - Check for similar URLs (fuzzy matching)
  - Store similar submission IDs in metadata
- [ ] If duplicate found:
  - Set `duplicate_of_id`
  - Set `status: :rejected`
  - Return early
- [ ] If similar found:
  - Store in `metadata['similar_submissions']`
  - Continue processing
- [ ] Add error handling
- [ ] Add logging

#### Step 2.5: Create Safety Check Job
**File**: `app/jobs/submission_processing/submission_safety_check_job.rb`

**Tasks:**
- [ ] Implement two-stage safety check:
  - **Stage 1 (Programmatic)**:
    - Check URL against blacklist
    - Check for malicious patterns
    - Validate URL accessibility
    - If fails, reject immediately
  - **Stage 2 (LLM)**:
    - Only if Stage 1 passes
    - Use RubyLLM to analyze content
    - Check for inappropriate content
    - If unsafe, reject with reason
- [ ] Add error handling
- [ ] Add logging
- [ ] Store rejection reason in metadata

#### Step 2.6: Create Metadata Extraction Job
**File**: `app/jobs/submission_processing/submission_metadata_extraction_job.rb`

**Tasks:**
- [ ] Implement web scraping:
  - Fetch URL content
  - Parse HTML with Nokogiri
  - Extract title (from `<title>`, Open Graph, Twitter Cards)
  - Extract description (from meta description, Open Graph)
  - Extract images (from Open Graph image, Twitter Card image)
  - Extract author information
  - Extract publication date
- [ ] Store in `metadata` JSONB column
- [ ] Update `submission_name` and `submission_description`
- [ ] Handle errors gracefully (some URLs may not be scrapable)
- [ ] Add caching to avoid re-scraping
- [ ] Respect robots.txt

#### Step 2.7: Create Type Classification Job (Stub → Working)
**File**: `app/jobs/submission_processing/submission_type_classification_job.rb`

**Tasks:**
- [ ] Set up RubyLLM integration
- [ ] Create RubyLLM Tool for type classification
- [ ] Implement classification:
  - Analyze URL, metadata, content
  - Classify submission type
  - Set `submission_type` enum
- [ ] Add error handling
- [ ] Add logging
- [ ] Test with various submission types

#### Step 2.8: Create Tool Detection Job (Stub → Working)
**File**: `app/jobs/submission_processing/submission_tool_detection_job.rb`

**Tasks:**
- [ ] Create RubyLLM Tool for tool detection
- [ ] Implement tool detection:
  - Analyze content, metadata, URL
  - Extract tool names mentioned
  - For each detected tool:
    - Check if Tool exists (by name matching)
    - If not, create new Tool instance
    - Link submission to Tool
- [ ] Store detected tools in `metadata['detected_tools']`
- [ ] Add error handling
- [ ] Add logging
- [ ] Test tool detection accuracy

#### Step 2.9: Create Tag Generation Job (Stub → Working)
**File**: `app/jobs/submission_processing/submission_tag_generation_job.rb`

**Tasks:**
- [ ] Create RubyLLM Tool for tag generation
- [ ] Implement tag generation:
  - Analyze content, metadata, submission type
  - Generate 3-10 relevant tags
  - Match to existing tags (fuzzy matching)
  - Create new tags if needed
  - Associate tags with submission
- [ ] Add error handling
- [ ] Add logging
- [ ] Test tag generation quality

#### Step 2.10: Create Summarization Job (Stub)
**File**: `app/jobs/submission_processing/submission_summarization_job.rb`

**Tasks:**
- [ ] Create stub implementation:
  - Log that summarization is not yet implemented
  - Return early without error
  - Placeholder for Phase 2
- [ ] Add TODO comment for Phase 2 implementation

#### Step 2.11: Create Embedding Generation Job (Working)
**File**: `app/jobs/submission_processing/submission_embedding_generation_job.rb`

**Tasks:**
- [ ] Set up OpenAI embeddings API integration
- [ ] Implement embedding generation:
  - Combine text from: title, description, author_note, scraped content, tags
  - Generate embedding using OpenAI API
  - Store embedding in `embedding` column (vector type)
- [ ] Handle errors gracefully
- [ ] Add logging
- [ ] Test embedding generation

#### Step 2.12: Create Relationship Discovery Job (Stub)
**File**: `app/jobs/submission_processing/submission_relationship_discovery_job.rb`

**Tasks:**
- [ ] Create stub implementation:
  - Log that relationship discovery is not yet implemented
  - Return early without error
  - Placeholder for Phase 2 implementation
- [ ] Add TODO comment for Phase 2 implementation

### Day 10-11: RubyLLM Integration

#### Step 2.13: Set Up RubyLLM Rails Integration
**Files**: 
- `config/initializers/ruby_llm.rb`
- Run: `rails generate ruby_llm:install`

**Tasks:**
- [ ] Install RubyLLM Rails integration (follow https://rubyllm.com/rails/)
- [ ] Configure RubyLLM:
  - Set OpenAI API key
  - Configure model defaults
  - Set up error handling
- [ ] Create initializer with configuration
- [ ] Test RubyLLM connection

#### Step 2.14: Create RubyLLM Tools
**Files**:
- `app/lib/ruby_llm_tools/submission_type_classification_tool.rb`
- `app/lib/ruby_llm_tools/submission_tool_detection_tool.rb`
- `app/lib/ruby_llm_tools/submission_tag_generation_tool.rb`
- `app/lib/ruby_llm_tools/submission_safety_tool.rb`

**Tasks:**
- [ ] Create Type Classification Tool:
  - Input: URL, metadata, content
  - Output: submission_type with confidence
  - Use RubyLLM::Schema for structured output
- [ ] Create Tool Detection Tool:
  - Input: content, metadata
  - Output: array of tool names with confidence
  - Use RubyLLM::Schema for structured output
- [ ] Create Tag Generation Tool:
  - Input: content, metadata, submission_type
  - Output: array of tag names with relevance scores
  - Use RubyLLM::Schema for structured output
- [ ] Create Safety Tool:
  - Input: content, URL, metadata
  - Output: safe/unsafe with reason and confidence
  - Use RubyLLM::Schema for structured output
- [ ] Test each tool individually
- [ ] Add error handling

#### Step 2.15: Update Processing Jobs to Use RubyLLM Tools
**Tasks:**
- [ ] Update Type Classification Job to use tool
- [ ] Update Tool Detection Job to use tool
- [ ] Update Tag Generation Job to use tool
- [ ] Update Safety Check Job to use tool
- [ ] Test end-to-end processing flow
- [ ] Add error handling and retries

### Day 12-13: Search Implementation

#### Step 2.16: Set Up pg_search
**File**: `app/models/submission.rb`

**Tasks:**
- [ ] Include `PgSearch::Model` in Submission model
- [ ] Configure multisearch:
  - Search across `submission_name`, `submission_description`, `author_note`
  - Use trigram for fuzzy matching
  - Configure ranking
- [ ] Add scoped search for submissions only
- [ ] Test search functionality

#### Step 2.17: Create Search Service
**File**: `app/services/submission_search_service.rb`

**Tasks:**
- [ ] Create service that combines:
  - PostgreSQL full-text search (`pg_search`)
  - Vector similarity search (embeddings)
  - Hybrid ranking algorithm
- [ ] Implement search method:
  - Generate query embedding
  - Find similar submissions using vector similarity
  - Find matching submissions using full-text search
  - Combine and rank results
  - Return top results
- [ ] Add filtering by submission_type, status, etc.
- [ ] Add pagination
- [ ] Test search performance

#### Step 2.18: Create RAG Service
**File**: `app/services/submission_rag_service.rb`

**Tasks:**
- [ ] Create RAG service:
  - Generate query embedding
  - Find top-K similar submissions using vector similarity
  - Use retrieved submissions as context
  - Generate enhanced search results with RubyLLM
- [ ] Implement context retrieval:
  - Retrieve top 5-10 similar submissions
  - Format as context for LLM
- [ ] Implement result enhancement:
  - Use RubyLLM to generate contextual summaries
  - Enhance search result descriptions
- [ ] Test RAG quality

#### Step 2.19: Update Search Controller
**File**: `app/controllers/search_controller.rb` or update `pages_controller.rb`

**Tasks:**
- [ ] Update search action to use Search Service
- [ ] Integrate RAG service for enhanced results
- [ ] Add filtering options
- [ ] Add pagination
- [ ] Handle Turbo Stream responses
- [ ] Test search UI

#### Step 2.20: Update Search UI
**File**: `app/views/pages/home.html.erb` or search view

**Tasks:**
- [ ] Update search form
- [ ] Display search results with:
  - Relevance scores
  - Submission type badges
  - Tags
  - Tool associations
- [ ] Add filters (by type, status, etc.)
- [ ] Add pagination
- [ ] Style with Bootstrap
- [ ] Make responsive

### Day 14: Testing & Integration

#### Step 2.21: Test Processing Pipeline
**Tasks:**
- [ ] Test each job individually
- [ ] Test orchestrator job
- [ ] Test end-to-end submission processing
- [ ] Test error handling
- [ ] Test retry logic
- [ ] Test Turbo Stream updates
- [ ] Performance testing

#### Step 2.22: Test Search & RAG
**Tasks:**
- [ ] Test full-text search
- [ ] Test vector similarity search
- [ ] Test hybrid search
- [ ] Test RAG enhancement
- [ ] Test search performance
- [ ] Test with various query types

#### Step 2.23: Integration Testing
**Tasks:**
- [ ] Test complete user flow:
  - User submits link
  - Processing pipeline runs
  - Submission appears with metadata
  - User can search and find submission
- [ ] Test error scenarios
- [ ] Test edge cases
- [ ] Fix any bugs found

## Week 3: Polish & Notifications

### Day 15-16: Notifications (Minimal)

#### Step 3.1: Install Noticed Gem
**File**: `Gemfile`

**Tasks:**
- [ ] Add `noticed` gem
- [ ] Run `bundle install`
- [ ] Run `rails generate noticed:install`
- [ ] Run migrations

#### Step 3.2: Create Basic Notifications
**Files**:
- `app/notifications/submission_processing_complete_notification.rb`
- `app/notifications/new_submission_notification.rb`

**Tasks:**
- [ ] Create Processing Complete notification:
  - Notify submitter when processing completes
  - Include submission details
- [ ] Create New Submission notification (stub for Phase 2):
  - Placeholder for notifying followers
- [ ] Set up database delivery
- [ ] Test notification creation

#### Step 3.3: Integrate Notifications
**Tasks:**
- [ ] Add notification creation to SubmissionProcessingJob
- [ ] Create minimal notification UI (or defer to Phase 2)
- [ ] Test notification delivery

### Day 17-18: UI/UX Polish

#### Step 3.4: Processing Status UI
**File**: `app/views/submissions/show.html.erb`

**Tasks:**
- [ ] Add processing status indicator
- [ ] Show status: pending, processing, completed, failed, rejected
- [ ] Add retry button for failed submissions
- [ ] Use Turbo Streams for real-time updates
- [ ] Style with Bootstrap

#### Step 3.5: Submission Cards
**File**: `app/views/submissions/_submission_card.html.erb`

**Tasks:**
- [ ] Display submission type badge
- [ ] Display tool associations
- [ ] Display tags
- [ ] Display processing status
- [ ] Add interaction buttons (upvote, favorite, follow)
- [ ] Style with Bootstrap
- [ ] Make responsive

#### Step 3.6: Error Handling UI
**Tasks:**
- [ ] Add error messages for failed processing
- [ ] Add rejection messages with reasons
- [ ] Add duplicate detection messages with link to original
- [ ] Add similar submissions suggestions
- [ ] Style error states

### Day 19-20: Performance & Optimization

#### Step 3.7: Database Optimization
**Tasks:**
- [ ] Review and optimize queries
- [ ] Add missing indexes
- [ ] Optimize N+1 queries
- [ ] Test query performance
- [ ] Add query logging in development

#### Step 3.8: Caching Strategy
**Tasks:**
- [ ] Cache scraped content
- [ ] Cache RubyLLM responses (where appropriate)
- [ ] Cache search results
- [ ] Use Redis for caching
- [ ] Test cache performance

#### Step 3.9: Job Performance
**Tasks:**
- [ ] Optimize job execution time
- [ ] Add job timeouts
- [ ] Optimize parallel execution
- [ ] Monitor job performance
- [ ] Add performance logging

### Day 21: Final Testing & Documentation

#### Step 3.10: Comprehensive Testing
**Tasks:**
- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Add missing test coverage
- [ ] Test on staging environment
- [ ] Performance testing
- [ ] Load testing (if applicable)

#### Step 3.11: Documentation
**Tasks:**
- [ ] Update `docs/SPECIFICATION.md` with Submission model
- [ ] Document processing pipeline
- [ ] Document RubyLLM integration
- [ ] Document search implementation
- [ ] Create README for Phase 1
- [ ] Document known issues and limitations

#### Step 3.12: Code Review & Cleanup
**Tasks:**
- [ ] Review all code for quality
- [ ] Remove debug code
- [ ] Add missing comments
- [ ] Ensure consistent code style
- [ ] Run RuboCop and fix violations
- [ ] Final code cleanup

## Testing Checklist

### Unit Tests
- [ ] Submission model validations
- [ ] Submission model associations
- [ ] Submission model scopes
- [ ] Submission model helper methods
- [ ] All processing jobs (individual tests)
- [ ] RubyLLM tools (individual tests)
- [ ] Search service
- [ ] RAG service

### Integration Tests
- [ ] Complete submission processing flow
- [ ] RubyLLM integration
- [ ] Search functionality
- [ ] RAG functionality
- [ ] Notification creation

### System Tests
- [ ] User submits link
- [ ] System processes submission
- [ ] User sees enriched submission
- [ ] User searches and finds submission
- [ ] User edits submission
- [ ] User deletes submission

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] API keys set up
- [ ] Redis configured
- [ ] PostgreSQL extensions enabled
- [ ] Background job queue configured

### Deployment
- [ ] Run migrations on production
- [ ] Deploy code
- [ ] Verify background jobs are processing
- [ ] Monitor error logs
- [ ] Test submission creation
- [ ] Test search functionality

### Post-Deployment
- [ ] Monitor performance
- [ ] Monitor error rates
- [ ] Monitor API costs
- [ ] Gather user feedback
- [ ] Fix any critical issues

## Success Criteria

Phase 1 is complete when:
- [ ] Users can create submissions (links)
- [ ] Processing pipeline runs successfully
- [ ] Classifications and tags are generated accurately
- [ ] Embeddings are generated for all submissions
- [ ] Search works with full-text and semantic search
- [ ] RAG enhances search results
- [ ] All tests pass
- [ ] Documentation is complete
- [ ] Code is production-ready

## Known Limitations (Phase 1)

- Summarization job is a stub (Phase 2)
- Relationship discovery job is a stub (Phase 2)
- Notifications are minimal (enhanced in Phase 2)
- Posts (text-only submissions) are not implemented (future)
- Advanced search features (faceting, etc.) are Phase 2
- Feed system is not implemented (future)

## Next Steps (Phase 2)

After Phase 1 completion:
1. Implement summarization job
2. Implement relationship discovery job
3. Enhance notification system
4. Add advanced search features
5. Performance optimization
6. User feedback integration


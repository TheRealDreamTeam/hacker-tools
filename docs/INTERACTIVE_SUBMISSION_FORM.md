# Interactive Submission Form - Implementation Guide

## Overview

The submission form has been enhanced to provide real-time validation, processing status updates, and duplicate detection as users paste URLs. This creates a much better user experience by:

1. **Real-time URL validation** - Validates URLs as users type
2. **Duplicate detection** - Finds exact duplicates and similar submissions
3. **Safety checks** - Validates content safety before submission
4. **Processing status** - Shows real-time updates as the pipeline runs
5. **Similar submissions** - Displays related content to prevent duplicates

## How It Works

### 1. Real-Time URL Validation

When a user pastes a URL into the submission form:

1. **Client-side validation** (Stimulus controller):
   - Validates URL format immediately
   - Debounces server requests (500ms delay)
   - Shows validation errors instantly

2. **Server-side validation** (`validate_url` action):
   - Checks for exact duplicates
   - Finds similar submissions using fuzzy matching
   - Runs programmatic safety checks
   - Returns JSON response with results

3. **UI updates**:
   - Shows validation errors/warnings
   - Displays similar submissions if found
   - Enables/disables submit button based on validation

### 2. Processing Pipeline with Real-Time Updates

After submission is created:

1. **Submission is saved** with `status: :pending`
2. **Processing job starts** (`SubmissionProcessingJob`)
3. **Turbo Stream broadcasts** update the UI after each phase:
   - Phase 1: Validating (duplicate check + safety check)
   - Phase 2: Extracting metadata
   - Phase 3: Enriching content (classification, tools, tags)
   - Phase 4: Generating embedding
   - Phase 5: Relationship discovery

4. **User sees updates** in real-time via Turbo Streams
5. **Auto-redirect** to submission show page when complete

## Components

### Stimulus Controller: `submission_form_controller.js`

**Responsibilities**:
- Validates URL format client-side
- Debounces server validation requests
- Updates UI based on validation results
- Handles similar submissions display
- Manages submit button state

**Key Methods**:
- `urlChanged()` - Called when URL input changes
- `validateUrl(url)` - Validates URL with server
- `handleDuplicate(data)` - Handles duplicate detection
- `handleSimilarSubmissions(submissions, explanation)` - Shows similar submissions
- `handleSafetyRejection(reason)` - Handles safety rejection

### Controller Action: `validate_url`

**Endpoint**: `POST /submissions/validate_url`

**Parameters**:
- `url` (required) - URL to validate
- `explain_similarity` (optional) - Whether to use RAG for similarity explanation

**Response**:
```json
{
  "duplicate": false,
  "safe": true,
  "similar_submissions": [
    {
      "id": 123,
      "name": "Submission Name",
      "url": "https://example.com",
      "path": "/submissions/123"
    }
  ],
  "explanation": "Optional RAG explanation of similarity"
}
```

### Safety Check Job: `SafetyCheckJob`

**Two-Stage Validation**:

1. **Stage 1: Programmatic Checks** (fast, low cost):
   - URL format validation
   - Domain blacklist check
   - Malicious pattern detection

2. **Stage 2: LLM Validation** (only if Stage 1 passes):
   - Content safety analysis
   - Inappropriate content detection
   - Spam detection

### Enhanced Duplicate Check: `DuplicateCheckJob`

**Features**:
- Exact duplicate detection (normalized URL)
- Fuzzy URL matching using PostgreSQL trigram
- Semantic similarity using embeddings
- Returns similar submissions for user review

## User Flow

### 1. User Pastes URL

```
User types: "https://example.com/article"
  ↓
Stimulus controller validates format
  ↓
Debounced request to /submissions/validate_url
  ↓
Server checks:
  - Exact duplicate? → Show error, disable submit
  - Similar submissions? → Show warning, allow submit
  - Safety check? → Show error if unsafe
  ↓
UI updates with results
```

### 2. User Submits Form

```
User clicks "Submit"
  ↓
Form submits to /submissions (POST)
  ↓
Submission created with status: :pending
  ↓
Processing job enqueued
  ↓
User redirected to submission show page
  ↓
Turbo Stream subscription active
  ↓
Real-time updates as processing progresses:
  - "Validating submission..."
  - "Extracting metadata..."
  - "Enriching content..."
  - "Generating embedding..."
  - "Processing complete!"
```

### 3. Processing Phases

Each phase broadcasts a Turbo Stream update:

```ruby
# Phase 1: Validation
broadcast_phase_update(submission, "validating", "Validating submission...")

# Phase 2: Metadata
broadcast_phase_update(submission, "extracting", "Extracting metadata...")

# Phase 3: Enrichment
broadcast_phase_update(submission, "enriching", "Enriching content...")

# Phase 4: Embedding
broadcast_phase_update(submission, "generating_embedding", "Generating embedding...")

# Complete
broadcast_status_update(submission, :completed, "Processing complete!")
```

## Turbo Stream Updates

### Subscription

The form subscribes to updates via:
```erb
<%= turbo_stream_from "submission_#{@submission.id}" %>
```

### Broadcasts

Processing job broadcasts updates to:
```ruby
Turbo::StreamsChannel.broadcast_update_to(
  "submission_#{submission.id}",
  target: "submission-processing-status-container",
  partial: "submissions/processing_status",
  locals: { submission: submission, status: status, message: message }
)
```

## UI Components

### Processing Status Partial

**File**: `app/views/submissions/_processing_status.html.erb`

**Displays**:
- Current processing phase
- Status message
- Loading spinner (when processing)
- Success/error styling

### Similar Submissions Display

Shown when similar submissions are found:
- List of similar submissions with links
- Optional RAG explanation of similarity
- Warning message to review before submitting

## Configuration

### Safety Check

**Domain Blacklist**: Edit `SafetyCheckJob#blacklisted_domains`

**Malicious Patterns**: Edit `SafetyCheckJob#programmatic_check`

### Duplicate Detection

**Similarity Threshold**: 
- URL similarity: 0.6 (60% similar)
- Semantic similarity: 0.7 cosine distance (70% similar)

**Max Similar Submissions**: 5

### Validation Debounce

**Delay**: 500ms (configurable in Stimulus controller)

## Future Enhancements

1. **RAG Similarity Explanations**: Use RAG to explain why submissions are similar
2. **Smart Tag Suggestions**: Suggest tags based on similar submissions
3. **Content Preview**: Show preview of scraped content before submission
4. **Batch Validation**: Validate multiple URLs at once
5. **Validation Caching**: Cache validation results for common URLs

## Testing

### Manual Testing

1. **Test URL Validation**:
   - Paste valid URL → Should validate successfully
   - Paste duplicate URL → Should show duplicate error
   - Paste similar URL → Should show similar submissions
   - Paste invalid URL → Should show format error

2. **Test Processing**:
   - Submit valid submission → Should see processing updates
   - Check Turbo Stream updates → Should update in real-time
   - Verify redirect → Should redirect when complete

3. **Test Safety Checks**:
   - Submit unsafe URL → Should be rejected
   - Check rejection reason → Should show clear message

### Automated Testing

TODO: Add system tests for:
- URL validation flow
- Duplicate detection
- Safety checks
- Turbo Stream updates
- Processing pipeline

## Troubleshooting

### Turbo Stream Updates Not Working

1. Check subscription: Ensure `turbo_stream_from` is in the view
2. Check broadcast target: Ensure target ID matches in partial
3. Check Action Cable: Ensure WebSocket connection is active
4. Check logs: Look for broadcast errors in Rails logs

### Validation Not Triggering

1. Check Stimulus controller: Ensure controller is connected
2. Check data attributes: Ensure `data-action` is set correctly
3. Check JavaScript console: Look for errors
4. Check network tab: Verify requests are being made

### Safety Check Failing

1. Check logs: Look for safety check errors
2. Check LLM API: Ensure RubyLLM is configured
3. Check content: Review what content is being validated
4. Check thresholds: Adjust safety check sensitivity if needed

## Summary

The interactive submission form provides a much better user experience by:

- ✅ **Preventing duplicates** before submission
- ✅ **Validating content** for safety
- ✅ **Showing processing progress** in real-time
- ✅ **Guiding users** with similar submissions
- ✅ **Providing clear feedback** at every step

This creates a professional, polished experience that helps users submit quality content while preventing issues before they occur.

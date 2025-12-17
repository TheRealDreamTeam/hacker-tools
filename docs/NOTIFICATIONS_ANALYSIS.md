# Notifications System Analysis & Implementation Plan

**Created**: 2025-01-XX  
**Updated**: 2025-01-XX (Updated with Noticed 2.0+ API from Context7)  
**Status**: Planning

## Overview

This document analyzes the current state of the application and identifies all notification opportunities, then outlines the implementation approach using Rails conventions and the Noticed gem.

## ⚠️ Important: Noticed 2.0+ API Changes

**CRITICAL**: This document has been updated with the latest Noticed 2.0+ API information fetched from Context7. Key changes:

- **Base Class**: Use `Noticed::Event` (not `Noticed::Base` or `ApplicationNotification`)
- **Directory**: Place notifiers in `app/notifiers/` (not `app/notifications/`)
- **Naming**: Use `Notifier` suffix (e.g., `NewCommentNotifier`) - creates `::Notification` subclass automatically
- **Database**: Two tables (`noticed_events` and `noticed_notifications`) instead of single `notifications` table
- **Installation**: Use `rails noticed:install:migrations` (not `rails noticed:install`)
- **Helper Methods**: Use `notification_methods` block (I18n and URL helpers available)
- **Record Parameter**: Use `record:` for polymorphic association to triggering object
- **Delivery**: Use `.with(params).deliver(recipients)` or `.deliver_later(recipients)`

## Current State Analysis

### Existing Infrastructure
- ✅ **Noticed gem**: Already in `Gemfile` but not yet installed/configured
- ✅ **Polymorphic Follow system**: Users can follow Users, Tools, Lists, Tags, and Submissions
- ✅ **Comment system**: Threaded comments on Tools and Submissions (polymorphic)
- ✅ **Flag/Bug system**: Special comment types (`flag`, `bug`) that can be resolved
- ✅ **Submission processing**: Background jobs process submissions with status tracking
- ✅ **Turbo Streams**: Real-time updates infrastructure already in place
- ✅ **Action Cable**: Redis adapter configured for WebSocket support

### Missing Components
- ❌ Notification model/database tables
- ❌ Notification classes (Noticed notification types)
- ❌ Notification UI (badge, dropdown, list)
- ❌ Notification delivery mechanisms
- ❌ Notification preferences/per-user settings

## Notification Opportunities

### 1. Follow-Based Notifications

#### 1.1. New Submission from Followed User
**Trigger**: When a user creates a new submission  
**Recipients**: All users following the submission creator  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice follows Bob → Bob submits "React Best Practices" → Alice gets notified

#### 1.2. New Submission on Followed Tool
**Trigger**: When a new submission is created about a tool  
**Recipients**: All users following that tool  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice follows "React" tool → Someone submits article about React → Alice gets notified

#### 1.3. New Submission on Followed Tag
**Trigger**: When a new submission is tagged with a tag  
**Recipients**: All users following that tag  
**Priority**: Medium  
**Frequency**: Real-time (immediate)

**Example**: Alice follows "frontend" tag → New submission tagged with "frontend" → Alice gets notified

#### 1.4. New Submission on Followed List
**Trigger**: When a submission is added to a list  
**Recipients**: All users following that list  
**Priority**: Low (may be too noisy)  
**Frequency**: Real-time (immediate)

**Note**: Consider if this is too granular - users might not want notifications for every list addition

### 2. Comment-Based Notifications

#### 2.1. New Top-Level Comment on Submission
**Trigger**: When a top-level comment is created on a submission  
**Recipients**: The submission owner  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Bob owns submission "React Best Practices" → Alice comments → Bob gets notified

#### 2.2. New Top-Level Comment on Tool
**Trigger**: When a top-level comment is created on a tool  
**Recipients**: Users who have commented on that tool (to keep them engaged)  
**Priority**: Medium  
**Frequency**: Real-time (immediate)

**Note**: Tools are community-owned, so we notify previous commenters, not an "owner"

#### 2.3. Reply to User's Comment
**Trigger**: When someone replies to a user's comment  
**Recipients**: The comment author  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice comments on submission → Bob replies to Alice's comment → Alice gets notified

#### 2.4. Reply in Thread User Participated In
**Trigger**: When someone replies in a thread where the user has commented  
**Recipients**: All users who have commented in that thread (excluding the replier)  
**Priority**: Low (may be too noisy)  
**Frequency**: Real-time (immediate)

**Note**: Consider making this opt-in via preferences - some users want to know about all thread activity, others only want direct replies

### 3. Flag/Bug Resolution Notifications

#### 3.1. Flag Resolved
**Trigger**: When a flag is marked as resolved (`solved: true`)  
**Recipients**: 
- The flag creator
- Users who upvoted the flag
- The submission/tool owner (if applicable)

**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice flags submission for inappropriate content → Admin resolves flag → Alice gets notified

#### 3.2. Bug Resolved
**Trigger**: When a bug is marked as resolved (`solved: true`)  
**Recipients**: 
- The bug reporter
- Users who upvoted the bug
- The submission/tool owner (if applicable)

**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice reports bug on tool → Tool owner resolves bug → Alice gets notified

### 4. Submission Processing Notifications

#### 4.1. Submission Processing Complete
**Trigger**: When submission status changes to `completed`  
**Recipients**: The submission creator  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice submits URL → Processing completes → Alice gets notified

#### 4.2. Submission Processing Failed
**Trigger**: When submission status changes to `failed`  
**Recipients**: The submission creator  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice submits URL → Processing fails → Alice gets notified with error details

#### 4.3. Submission Rejected
**Trigger**: When submission status changes to `rejected` (duplicate, unsafe, etc.)  
**Recipients**: The submission creator  
**Priority**: High  
**Frequency**: Real-time (immediate)

**Example**: Alice submits duplicate URL → Submission rejected → Alice gets notified with reason

### 5. Engagement Notifications (Optional - Lower Priority)

#### 5.1. Comment Upvoted
**Trigger**: When a user's comment receives an upvote  
**Recipients**: The comment author  
**Priority**: Low (may be too noisy)  
**Frequency**: Batched (digest) or threshold-based (e.g., notify after 5 upvotes)

**Note**: Consider making this opt-in - some users want to know about every upvote, others find it noisy

#### 5.2. Submission Upvoted
**Trigger**: When a user's submission receives an upvote  
**Recipients**: The submission creator  
**Priority**: Low (may be too noisy)  
**Frequency**: Batched (digest) or threshold-based

**Note**: Consider making this opt-in or threshold-based to avoid notification spam

## Implementation Approach: Noticed Gem

### Why Noticed?

The [Noticed gem](https://github.com/excid3/noticed) is the Rails community standard for notifications:

- ✅ **Mature & Well-Maintained**: Actively maintained by Chris Oliver (GoRails)
- ✅ **Rails Conventions**: Follows Rails patterns and conventions
- ✅ **Multiple Delivery Channels**: Database, email, Action Cable, SMS, Slack, etc.
- ✅ **Turbo Streams Integration**: Built-in support for real-time updates
- ✅ **Flexible**: Easy to extend with custom delivery methods
- ✅ **Active Record Integration**: Stores notifications in database for history

### Rails Conventions

Noticed follows Rails conventions:
- **Noticed 2.0+**: Notification classes inherit from `Noticed::Event` (not `Noticed::Base` or `ApplicationNotification`)
- Database delivery via `Noticed::Event` and `Noticed::Notification` models (Active Record)
- Action Cable delivery for real-time updates
- Turbo Streams integration via custom delivery methods
- Standard Rails patterns (callbacks, validations, associations)

### Database Schema

Noticed 2.0+ creates two tables:

**`noticed_events` table:**
- `id` (primary key)
- `type` (string - notification class name, e.g., "NewCommentNotifier")
- `record_id` and `record_type` (polymorphic - the object that triggered the notification)
- `params` (JSONB - flexible data storage for notification parameters)
- `created_at`, `updated_at` (timestamps)

**`noticed_notifications` table:**
- `id` (primary key)
- `type` (string - notification class name with `::Notification` suffix)
- `event_id` (foreign key to `noticed_events`)
- `recipient_type` and `recipient_id` (polymorphic - who receives it)
- `read_at` (datetime - when notification was read)
- `seen_at` (datetime - when notification was seen)
- `created_at`, `updated_at` (timestamps)

### Notification Class Structure

```ruby
# app/notifiers/new_submission_notifier.rb
class NewSubmissionNotifier < Noticed::Event
  # Database delivery (default - creates Noticed::Notification records)
  deliver_by :database
  
  # Action Cable delivery for real-time updates
  deliver_by :action_cable do |config|
    config.channel = "Noticed::NotificationChannel"
    config.stream = -> { recipient }
    config.message = :to_websocket
  end
  
  # Email delivery (optional)
  # deliver_by :email do |config|
  #   config.mailer = "NotificationMailer"
  #   config.method = :new_submission
  #   config.if = -> { recipient.email_notifications? }
  # end
  
  # Helper methods accessible in notifications via notification_methods block
  notification_methods do
    # I18n helpers are available here
    def message
      t(".message", username: params[:user].username, submission_name: params[:submission].submission_name)
    end
    
    # URL helpers are available here too
    def url
      submission_path(params[:submission])
    end
  end
  
  # Optional: Custom websocket message format
  def to_websocket(notification)
    {
      id: notification.id,
      message: notification.message,
      url: notification.url,
      created_at: notification.created_at
    }
  end
end
```

### Triggering Notifications

```ruby
# In Submission model after_create callback or controller
# The 'record:' parameter is special - it gets assigned to the polymorphic 'record' association
NewSubmissionNotifier.with(
  record: @submission,  # Special parameter for polymorphic association
  submission: @submission,
  user: @submission.user
).deliver(@submission.followers)  # or .deliver_later for background processing

# For multiple recipients
NewSubmissionNotifier.with(record: @submission, submission: @submission, user: @submission.user)
  .deliver_later(@submission.followers)
```

## Implementation Plan

### Phase 1: Foundation (Core Notifications)

1. **Install & Configure Noticed**
   - Run `bundle add "noticed"` (already in Gemfile)
   - Run `rails noticed:install:migrations` to generate migrations
   - Run `rails db:migrate` to create `noticed_events` and `noticed_notifications` tables
   - Configure Action Cable delivery in notification classes

2. **Create Core Notification Classes** (in `app/notifiers/` directory)
   - `NewSubmissionFromFollowedUserNotifier` (inherits from `Noticed::Event`)
   - `NewSubmissionOnFollowedToolNotifier`
   - `NewSubmissionOnFollowedTagNotifier`
   - `NewTopLevelCommentNotifier`
   - `ReplyToCommentNotifier`
   - `FlagResolvedNotifier`
   - `BugResolvedNotifier`
   - `SubmissionProcessingCompleteNotifier`
   - `SubmissionProcessingFailedNotifier`
   - `SubmissionRejectedNotifier`

3. **Add Notification Triggers**
   - Submission creation → notify followers
   - Comment creation → notify submission/tool owner
   - Comment reply → notify parent comment author
   - Flag/Bug resolution → notify relevant users
   - Submission processing → notify submitter

4. **Basic Notification UI**
   - Notification badge in header (unread count)
   - Notification dropdown/list
   - Mark as read functionality
   - Link to notification target

### Phase 2: Enhanced Features

1. **Notification Preferences**
   - Per-user settings for notification types
   - Opt-in/opt-out for each notification type
   - Frequency settings (real-time vs digest)

2. **Advanced UI**
   - Notification center page
   - Filter by notification type
   - Mark all as read
   - Delete notifications

3. **Email Delivery** (Optional)
   - Email notifications for important events
   - Digest emails for less urgent notifications

4. **Batching & Throttling**
   - Batch similar notifications (e.g., multiple upvotes)
   - Rate limiting to prevent spam
   - Digest mode for low-priority notifications

## Notification Priority Matrix

| Notification Type | Priority | Frequency | Delivery Method |
|------------------|----------|-----------|-----------------|
| New submission from followed user | High | Real-time | Database + Action Cable |
| New top-level comment | High | Real-time | Database + Action Cable |
| Reply to comment | High | Real-time | Database + Action Cable |
| Flag/Bug resolved | High | Real-time | Database + Action Cable |
| Submission processing complete | High | Real-time | Database + Action Cable |
| New submission on followed tool | High | Real-time | Database + Action Cable |
| New submission on followed tag | Medium | Real-time | Database + Action Cable |
| Comment upvoted | Low | Batched/Digest | Database only |
| Submission upvoted | Low | Batched/Digest | Database only |
| Reply in thread | Low | Opt-in | Database only |

## Database Considerations

### Indexes Needed
- `index_noticed_notifications_on_recipient` (recipient_type, recipient_id)
- `index_noticed_notifications_on_read_at` (for unread queries)
- `index_noticed_notifications_on_created_at` (for sorting)
- `index_noticed_notifications_on_type` (for filtering by notification type)
- `index_noticed_notifications_on_event_id` (for joining with events)
- `index_noticed_events_on_record` (record_type, record_id) - for querying by record

### Performance Considerations
- **Batch notifications**: Use `deliver_later` for background processing
- **Eager loading**: Include notification associations when loading lists
- **Pagination**: Limit notification queries (e.g., last 50)
- **Cleanup**: Archive or delete old notifications (e.g., older than 90 days)

## Testing Strategy

### Unit Tests
- Test notification creation with correct params
- Test notification delivery to correct recipients
- Test notification message formatting

### Integration Tests
- Test notification triggers from model callbacks
- Test notification delivery via Action Cable
- Test notification UI (badge, dropdown, read state)

### System Tests
- Test complete user flows (comment → notification → read)
- Test notification real-time updates via Turbo Streams

## Security Considerations

- **Authorization**: Ensure users can only see their own notifications
- **Rate Limiting**: Prevent notification spam (e.g., max 100 notifications/hour)
- **Privacy**: Don't expose sensitive data in notification messages
- **XSS Prevention**: Sanitize user-generated content in notifications

## Future Enhancements

1. **Notification Groups**: Group similar notifications (e.g., "5 new comments on your submission")
2. **Smart Notifications**: ML-based prioritization of notifications
3. **Mobile Push**: Push notifications for mobile apps
4. **Notification Analytics**: Track notification engagement (open rates, click rates)
5. **Custom Notification Types**: Allow users to create custom notification rules

## References

- [Noticed Gem Documentation](https://github.com/excid3/noticed)
- [Noticed Rails Integration](https://github.com/excid3/noticed#rails-integration)
- [Action Cable Guide](https://guides.rubyonrails.org/action_cable_overview.html)
- [Turbo Streams Guide](https://turbo.hotwired.dev/handbook/streams)


# Notifications System Implementation Prompt

## Context

I need to implement a comprehensive notifications system for my Rails 7 + Hotwire application. The application already has:

- **Noticed gem** in the Gemfile (not yet installed/configured)
- **Polymorphic Follow system** (users can follow Users, Tools, Lists, Tags, Submissions)
- **Comment system** (threaded comments on Tools and Submissions)
- **Flag/Bug system** (special comment types that can be resolved)
- **Submission processing** (background jobs with status tracking)
- **Turbo Streams** infrastructure for real-time updates
- **Action Cable** configured with Redis

## Requirements

### Core Notifications to Implement

1. **Follow-Based Notifications**
   - New submission from followed user → notify all followers
   - New submission on followed tool → notify all tool followers
   - New submission on followed tag → notify all tag followers

2. **Comment-Based Notifications**
   - New top-level comment on submission → notify submission owner
   - New top-level comment on tool → notify users who previously commented (tools are community-owned)
   - Reply to user's comment → notify the comment author
   - Reply in thread user participated in → notify all thread participants (opt-in via preferences)

3. **Flag/Bug Resolution Notifications**
   - Flag resolved → notify flag creator, upvoters, and submission/tool owner
   - Bug resolved → notify bug reporter, upvoters, and submission/tool owner

4. **Submission Processing Notifications**
   - Submission processing complete → notify submitter
   - Submission processing failed → notify submitter with error details
   - Submission rejected → notify submitter with reason

### Implementation Requirements

1. **Install & Configure Noticed**
   - Run `bundle install` (gem already in Gemfile)
   - Run `rails noticed:install:migrations` to generate migrations
   - Run `rails db:migrate` to create `noticed_events` and `noticed_notifications` tables
   - Configure database delivery (default - automatically enabled)
   - Configure Action Cable delivery in each notification class for real-time updates
   - Set up Turbo Streams integration via custom delivery method or Action Cable

2. **Create Notification Classes**
   - Create notification classes in `app/notifiers/` directory (Noticed convention)
   - All classes must inherit from `Noticed::Event` (Noticed 2.0+ API)
   - Use `deliver_by :database` (default) + `deliver_by :action_cable` for real-time notifications
   - Use `notification_methods` block for helper methods (message, url, etc.)
   - Include I18n translations for notification messages
   - Follow Rails conventions and project patterns

3. **Add Notification Triggers**
   - Add callbacks/notifications in appropriate models/controllers:
     - `Submission` model: after_create → notify followers using `.with(record: @submission, ...).deliver_later(followers)`
     - `Comment` model: after_create → notify submission/tool owner or parent comment author
     - `Comment` model: after_update (when solved changes) → notify relevant users
     - `SubmissionProcessingJob`: after status changes → notify submitter
   - Use `.deliver_later(recipients)` for background processing (or `.deliver(recipients)` for synchronous)
   - Use `record:` parameter for polymorphic association to the triggering object
   - Handle edge cases (self-notifications, deleted users, etc.)

4. **Notification UI**
   - Add notification badge to header (shows unread count)
   - Create notification dropdown/list component
   - Implement mark as read functionality
   - Add link to notification target (submission, comment, etc.)
   - Use Turbo Streams for real-time badge updates
   - Style with Bootstrap (consistent with existing UI)

5. **Database Setup**
   - Run `rails db:migrate` after `rails noticed:install:migrations`
   - Creates `noticed_events` and `noticed_notifications` tables
   - Add necessary indexes for performance (may be included in migration):
     - `index_noticed_notifications_on_recipient` (recipient_type, recipient_id)
     - `index_noticed_notifications_on_read_at` (for unread queries)
     - `index_noticed_notifications_on_created_at` (for sorting)
     - `index_noticed_notifications_on_type` (for filtering by notification type)
     - `index_noticed_notifications_on_event_id` (for joining with events)
     - `index_noticed_events_on_record` (record_type, record_id)

6. **Testing**
   - Write unit tests for notification classes
   - Write integration tests for notification triggers
   - Write system tests for notification UI flows
   - Test real-time updates via Turbo Streams

### Technical Constraints

- **Server-first architecture**: All logic server-side, minimal client-side JS
- **Turbo Streams**: Use for real-time UI updates
- **Bootstrap styling**: Follow existing design system
- **Rails conventions**: Follow Rails MVC patterns and Noticed gem patterns
- **Performance**: Use background jobs (`deliver_later`), batch notifications where appropriate
- **Security**: Ensure users can only see their own notifications, sanitize user content

### Files to Create/Modify

**New Files:**
- `app/notifiers/application_notifier.rb` (optional base class, inherits from `Noticed::Event`)
- `app/notifiers/new_submission_from_followed_user_notifier.rb` (inherits from `Noticed::Event`)
- `app/notifiers/new_submission_on_followed_tool_notifier.rb`
- `app/notifiers/new_submission_on_followed_tag_notifier.rb`
- `app/notifiers/new_top_level_comment_notifier.rb`
- `app/notifiers/reply_to_comment_notifier.rb`
- `app/notifiers/flag_resolved_notifier.rb`
- `app/notifiers/bug_resolved_notifier.rb`
- `app/notifiers/submission_processing_complete_notifier.rb`
- `app/notifiers/submission_processing_failed_notifier.rb`
- `app/notifiers/submission_rejected_notifier.rb`
- `app/channels/noticed/notification_channel.rb` (Action Cable channel for real-time updates)
- `app/views/notifications/_notification.html.erb` (notification partial)
- `app/views/notifications/_dropdown.html.erb` (dropdown component)
- `app/controllers/notifications_controller.rb` (mark as read, index)
- `app/helpers/notifications_helper.rb` (helper methods)
- `test/models/notification_test.rb`
- `test/notifications/*_test.rb` (notification class tests)

**Modified Files:**
- `app/models/submission.rb` (add notification triggers)
- `app/models/comment.rb` (add notification triggers)
- `app/jobs/submission_processing_job.rb` (add notification triggers)
- `app/views/layouts/application.html.erb` (add notification badge/dropdown)
- `config/routes.rb` (add notifications routes)
- `config/locales/en.yml` (add notification translations)

### Implementation Steps

1. **Install Noticed**: Run `bundle install`, then `rails noticed:install:migrations`, review generated migration files
2. **Create Base Notifier** (optional): Set up `ApplicationNotifier` inheriting from `Noticed::Event` with common delivery methods
3. **Create Notification Classes**: Implement each notification type following Noticed patterns
4. **Add Triggers**: Add notification triggers in models/controllers with proper error handling
5. **Build UI**: Create notification badge, dropdown, and list views
6. **Add Routes**: Add notifications routes (index, mark as read, mark all as read)
7. **Add Translations**: Add i18n keys for all notification messages
8. **Write Tests**: Test notification creation, delivery, and UI
9. **Performance**: Add indexes, optimize queries, use background jobs
10. **Documentation**: Update `docs/SPECIFICATION.md` with notification system details

### Success Criteria

- ✅ Users receive notifications when followed users create submissions
- ✅ Users receive notifications for new comments on their submissions
- ✅ Users receive notifications for replies to their comments
- ✅ Users receive notifications when flags/bugs are resolved
- ✅ Users receive notifications when their submissions finish processing
- ✅ Notification badge shows unread count in real-time
- ✅ Notification dropdown shows recent notifications
- ✅ Users can mark notifications as read
- ✅ Notifications link to correct targets (submissions, comments, etc.)
- ✅ Real-time updates work via Turbo Streams
- ✅ All tests pass
- ✅ Performance is acceptable (no N+1 queries, proper indexing)

### Questions to Consider

- Should we notify users about their own actions? (e.g., don't notify when you comment on your own submission)
- How should we handle deleted users? (skip notifications, show anonymized names)
- Should we batch similar notifications? (e.g., "5 new comments on your submission")
- What's the notification retention policy? (delete after 90 days? archive?)
- Should we add notification preferences in Phase 1 or defer to Phase 2?

### References

- See `docs/NOTIFICATIONS_ANALYSIS.md` for detailed analysis of all notification opportunities
- [Noticed Gem Documentation](https://github.com/excid3/noticed)
- [Noticed 2.0 Upgrade Guide](https://github.com/excid3/noticed/blob/main/UPGRADE.md) - Important for API changes
- [Action Cable Delivery Method](https://github.com/excid3/noticed/blob/main/docs/delivery_methods/action_cable.md)
- Existing Turbo Streams patterns in the codebase (e.g., `tools/interaction_update.turbo_stream.erb`)

### Important Noticed 2.0+ API Notes

- **Base Class**: Use `Noticed::Event` as parent class (not `Noticed::Base` or `ApplicationNotification`)
- **Directory**: Place notifiers in `app/notifiers/` (not `app/notifications/`)
- **Naming**: Use `Notifier` suffix (e.g., `NewCommentNotifier`) - Noticed automatically creates `::Notification` subclass
- **Params**: Use `params` hash to access notification data (e.g., `params[:submission]`)
- **Record**: Use `record:` parameter for polymorphic association to triggering object
- **Delivery**: Use `.with(params).deliver(recipients)` or `.deliver_later(recipients)`
- **Helper Methods**: Use `notification_methods` block for message, url, etc. (I18n and URL helpers available)
- **Action Cable**: Configure with `deliver_by :action_cable` block specifying channel, stream, and message


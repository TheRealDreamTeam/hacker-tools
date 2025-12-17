# Notifications System Testing Guide

## Prerequisites

### 1. Install Noticed Migrations (if not done)
```bash
rails noticed:install:migrations
rails db:migrate
```

### 2. Verify Database Tables
Check that these tables exist:
- `noticed_events`
- `noticed_notifications`

```bash
rails db:migrate:status | grep noticed
```

### 3. Start Rails Server
```bash
rails server
```

### 4. Start Action Cable (if using separate process)
```bash
# Action Cable should run automatically with Rails server
# If using separate Redis server, ensure it's running:
redis-server
```

---

## Testing Scenarios

### Test 1: Manual Notification Creation (Rails Console)

**Purpose**: Verify the notification system works end-to-end

**Steps**:
1. Open Rails console: `rails console`
2. Get two users (or create test users):
   ```ruby
   user1 = User.first
   user2 = User.second
   # Or create test users:
   # user1 = User.create!(email: "test1@example.com", password: "password123", username: "test1")
   # user2 = User.create!(email: "test2@example.com", password: "password123", username: "test2")
   ```
3. Create a test notification manually:
   ```ruby
   # Test NewSubmissionFromFollowedUserNotifier
   submission = Submission.first || Submission.create!(
     user: user1,
     submission_url: "https://example.com/test",
     status: "completed"
   )
   
   NewSubmissionFromFollowedUserNotifier.with(
     record: submission,
     submission: submission,
     user: user1
   ).deliver_later(user2)
   ```
4. Check if notification was created:
   ```ruby
   user2.notifications.count
   user2.unread_notifications.count
   user2.has_unread_notifications?
   ```
5. View notification details:
   ```ruby
   notification = user2.notifications.last
   notification.message
   notification.url
   notification.read_at
   ```

**Expected Result**: 
- Notification is created in database
- `unread_notifications_count` returns 1
- `has_unread_notifications?` returns true
- Notification has message and URL

---

### Test 2: Notification Badge in Navbar

**Purpose**: Verify the notification bell icon displays unread count

**Steps**:
1. Log in as `user2` (the user who received the notification)
2. Look at the navbar - you should see a bell icon (🔔) in the top right
3. Check if there's a red badge with a number showing unread count
4. Click the bell icon to open the dropdown

**Expected Result**:
- Bell icon is visible in navbar
- Red badge shows correct unread count (e.g., "1")
- Clicking bell opens dropdown with notifications

---

### Test 3: Notification Dropdown Display

**Purpose**: Verify notifications appear in the dropdown

**Steps**:
1. While logged in as `user2`, click the bell icon
2. Check the dropdown shows:
   - Header with "Notifications" title
   - "Mark all as read" link (if unread notifications exist)
   - List of notifications (up to 10 most recent)
   - Each notification shows:
     - Message text
     - Timestamp (e.g., "2 minutes ago")
     - Link to the related content
   - Footer with "View all" link

**Expected Result**:
- Dropdown displays correctly
- Notifications are listed in reverse chronological order (newest first)
- Each notification is clickable and links to the related content

---

### Test 4: Mark Notification as Read

**Purpose**: Verify marking individual notifications as read works

**Steps**:
1. In the notification dropdown, click on a notification (or the "Mark as read" button if present)
2. The notification should be marked as read
3. Check the badge count decreases
4. Refresh the page - the notification should still be marked as read

**Expected Result**:
- Clicking notification marks it as read
- Badge count decreases
- Notification no longer appears in unread count
- State persists after page refresh

---

### Test 5: Mark All as Read

**Purpose**: Verify bulk mark-as-read functionality

**Steps**:
1. Create multiple notifications (use Rails console from Test 1)
2. Log in as the user with notifications
3. Click bell icon to open dropdown
4. Click "Mark all as read" link in dropdown header
5. Verify badge count goes to 0
6. Verify all notifications are marked as read

**Expected Result**:
- All notifications marked as read
- Badge count shows 0
- "Mark all as read" link disappears (no unread notifications)

---

### Test 6: Notifications Index Page

**Purpose**: Verify the full notifications page works

**Steps**:
1. Log in as user with notifications
2. Click "View all" link in dropdown (or navigate to `/notifications`)
3. Verify page shows:
   - All notifications (up to 50 most recent)
   - Pagination if needed
   - Ability to mark individual notifications as read
   - Ability to mark all as read

**Expected Result**:
- Page loads correctly
- All notifications displayed
- Mark as read functionality works
- Page is accessible and styled correctly

---

### Test 7: New Submission from Followed User

**Purpose**: Test automatic notification when a followed user creates a submission

**Steps**:
1. Set up follow relationship:
   ```ruby
   # In Rails console
   user1 = User.first
   user2 = User.second
   Follow.create!(user: user2, followable: user1)
   ```
2. Log in as `user1`
3. Create a new submission:
   - Navigate to "New Submission"
   - Enter a URL (e.g., "https://example.com/article")
   - Submit
4. Log in as `user2` (the follower)
5. Check notification badge - should show 1 unread notification
6. Open dropdown - should see notification about new submission

**Expected Result**:
- Notification created automatically when submission is created
- Follower receives notification
- Notification links to the new submission

---

### Test 8: New Top-Level Comment on Submission

**Purpose**: Test notification when someone comments on your submission

**Steps**:
1. Log in as `user1` and create a submission (or use existing)
2. Log in as `user2` (different user)
3. Navigate to `user1`'s submission
4. Add a top-level comment
5. Log back in as `user1` (submission owner)
6. Check notification badge - should show 1 unread notification
7. Open dropdown - should see notification about new comment

**Expected Result**:
- Submission owner receives notification
- Notification links to the comment/submission
- Notification message indicates who commented

---

### Test 9: Reply to Comment

**Purpose**: Test notification when someone replies to your comment

**Steps**:
1. Log in as `user1` and create a submission
2. Log in as `user2` and add a top-level comment
3. Log in as `user1` and reply to `user2`'s comment
4. Log back in as `user2` (original commenter)
5. Check notification badge - should show 1 unread notification
6. Open dropdown - should see notification about reply

**Expected Result**:
- Comment author receives notification about reply
- Notification links to the reply/submission
- Notification message indicates who replied

---

### Test 10: Real-Time Updates (Action Cable)

**Purpose**: Test that notifications appear in real-time without page refresh

**Steps**:
1. Open browser as `user2` (logged in)
2. Open browser DevTools → Network tab → Filter by "WS" (WebSocket)
3. Verify WebSocket connection is established (should see connection to `/cable`)
4. In another browser/tab, log in as `user1`
5. Create a submission that `user2` follows (or comment on `user2`'s submission)
6. Watch `user2`'s browser - notification should appear automatically without refresh
7. Badge count should update automatically

**Expected Result**:
- WebSocket connection established
- Notification appears in real-time
- Badge count updates automatically
- No page refresh needed

**Troubleshooting**:
- If WebSocket doesn't connect, check:
  - Redis is running: `redis-cli ping` (should return "PONG")
  - Action Cable config in `config/cable.yml`
  - Check browser console for WebSocket errors

---

### Test 11: Submission Processing Notifications

**Purpose**: Test notifications for submission status changes

**Steps**:
1. Log in as `user1`
2. Create a new submission
3. In Rails console, manually trigger status change:
   ```ruby
   submission = Submission.last
   submission.update!(status: "completed")
   # Or simulate processing failure:
   # submission.update!(status: "failed", metadata: { error: "Test error" })
   ```
4. Check notification badge - should show notification
5. Open dropdown - should see notification about processing status

**Expected Result**:
- Notification created when status changes
- Correct notification type based on status (completed/failed/rejected)
- Notification includes relevant details (error message for failures)

---

### Test 12: Flag/Bug Resolution Notifications

**Purpose**: Test notifications when flags/bugs are resolved

**Steps**:
1. Log in as `user1` and create a submission
2. Log in as `user2` and add a comment with `comment_type: :flag` or `comment_type: :bug`
3. Log in as `user1` (or admin) and mark the flag/bug as resolved:
   ```ruby
   # In Rails console
   comment = Comment.where(comment_type: [:flag, :bug]).last
   comment.update!(solved: true)
   ```
4. Log back in as `user2` (flag creator)
5. Check notification badge - should show notification about resolution

**Expected Result**:
- Flag/bug creator receives notification when resolved
- Notification links to the resolved flag/bug
- Notification message indicates resolution

---

## Quick Test Checklist

Use this checklist to quickly verify all functionality:

- [ ] Database migrations run successfully
- [ ] Manual notification creation works (Rails console)
- [ ] Notification badge displays in navbar
- [ ] Badge shows correct unread count
- [ ] Dropdown opens and displays notifications
- [ ] Individual notifications can be marked as read
- [ ] "Mark all as read" works
- [ ] Notifications index page loads
- [ ] New submission from followed user creates notification
- [ ] New comment on submission creates notification
- [ ] Reply to comment creates notification
- [ ] Real-time updates work (Action Cable)
- [ ] Submission processing notifications work
- [ ] Flag/bug resolution notifications work

---

## Troubleshooting

### Notifications Not Appearing

1. **Check database**:
   ```ruby
   # In Rails console
   Noticed::Notification.count
   User.first.notifications.count
   ```

2. **Check background jobs**:
   ```ruby
   # Check if jobs are queued
   ActiveJob::Base.queue_adapter.enqueued_jobs
   # Process jobs manually in development:
   ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
   ```

3. **Check Action Cable**:
   - Verify Redis is running
   - Check browser console for WebSocket errors
   - Verify `config/cable.yml` is configured correctly

### Badge Not Updating

1. **Check Turbo Stream subscription**:
   - Verify `turbo_stream_from` is in the view
   - Check browser DevTools for Turbo Stream connections

2. **Check Stimulus controller**:
   - Verify `notifications_controller.js` is loaded
   - Check browser console for JavaScript errors

### Real-Time Updates Not Working

1. **Check Action Cable connection**:
   - Browser DevTools → Network → WS filter
   - Should see `/cable` connection

2. **Check Redis**:
   ```bash
   redis-cli ping
   ```

3. **Check Noticed configuration**:
   - Verify `deliver_by :action_cable` is in `ApplicationNotifier`
   - Verify channel is configured correctly

---

## Next Steps After Testing

Once basic functionality is verified:

1. **Write automated tests** (unit, integration, system tests)
2. **Test edge cases**:
   - Deleted users
   - Users following themselves
   - Multiple rapid notifications
   - Very long notification messages
3. **Performance testing**:
   - Many followers (100+)
   - Many notifications (1000+)
   - Concurrent notifications
4. **UI/UX improvements**:
   - Loading states
   - Error handling
   - Empty states
   - Notification grouping


# Soft Delete Functionality - Manual Testing Guide

This document provides manual browser testing steps to verify soft delete functionality. Automated tests cover the technical implementation, so this guide focuses on user-facing behavior.

## Prerequisites

1. Start Rails server: `bin/rails server`
2. Open browser to `http://localhost:3000`
3. (Optional) Have Rails console ready for setup: `bin/rails console`

---

## Test 1: Account Deletion via UI

### Complete Account Deletion Flow

1. **Sign up a new user:**
   - Go to `http://localhost:3000/users/sign_up`
   - Create a new account with email and username
   - Sign in

2. **Create some content:**
   - Create a tool
   - Add a comment to a tool
   - Create a list (if applicable)

3. **Navigate to Account Settings:**
   - Click on profile/account settings link
   - Go to `http://localhost:3000/account_settings`

4. **Delete Account:**
   - Scroll to "Delete Account" section
   - Click "Delete Account" button
   - Modal should appear
   - Enter your password
   - Click confirmation button

5. **Verify Results:**
   - ✅ Should be redirected to home page
   - ✅ Should see success message
   - ✅ Should be signed out (no user menu visible)
   - ✅ Cannot access protected pages (redirected to login)

**Expected Result:** Account deletion works via UI, user is signed out, and cannot access the account anymore.

---

## Test 2: Deleted User Cannot Log In

1. **After deleting an account (from Test 1), try to log in:**
   - Go to `http://localhost:3000/users/sign_in`
   - Enter the email you used before deletion
   - Enter the password
   - Click "Log in"

**Expected Result:**
- ✅ Login fails
- ✅ Error message: "This account has been deleted." (or similar)
- ✅ User is NOT signed in
- ✅ Remains on login page

---

## Test 3: Password Validation on Deletion

### 3.1 Test Incorrect Password

1. **Log in as a user**
2. **Go to Account Settings**
3. **Click "Delete Account"**
4. **Enter wrong password in modal**
5. **Click confirmation**

**Expected Result:**
- ✅ Account is NOT deleted
- ✅ Error message shown: "is incorrect"
- ✅ User remains signed in
- ✅ Modal stays open or shows error

### 3.2 Test Correct Password

1. **Log in as a user**
2. **Go to Account Settings**
3. **Click "Delete Account"**
4. **Enter correct password**
5. **Click confirmation**

**Expected Result:**
- ✅ Account is deleted
- ✅ User is signed out
- ✅ Redirected to home page
- ✅ Success message displayed

---

## Test 4: UI Display of Deleted Users

### 4.1 Test Comment Display with Deleted User

**Setup (in Rails console):**
```ruby
user = User.create!(email: "commenter@example.com", username: "commenter", password: "password123")
tool_owner = User.create!(email: "owner@example.com", username: "owner", password: "password123")
tool = Tool.create!(user: tool_owner, tool_name: "Test Tool", tool_url: "https://example.com", visibility: :public)
comment = Comment.create!(user: user, tool: tool, comment: "This is a test comment", comment_type: :comment)
user.soft_delete!
```

**Browser Test:**
1. Log in as any user
2. Go to the tool page: `http://localhost:3000/tools/#{tool.id}`
3. Find the comment

**Expected Result:**
- ✅ Comment is displayed
- ✅ Author shows as "Deleted Account" instead of username/email
- ✅ Comment content is still visible

### 4.2 Test Tool Owner Display with Deleted User

**Setup (in Rails console):**
```ruby
user = User.create!(email: "tool_owner@example.com", username: "tool_owner", password: "password123")
tool = Tool.create!(user: user, tool_name: "Owner's Tool", tool_url: "https://example.com", visibility: :public)
user.soft_delete!
```

**Browser Test:**
1. Log in as any user
2. Go to `http://localhost:3000/tools` (index page)
3. Find the tool - check owner display
4. Go to `http://localhost:3000/tools/#{tool.id}` (show page)
5. Check owner display

**Expected Result:**
- ✅ Tool is displayed on index page
- ✅ Owner shows as "Deleted Account" on index page
- ✅ Tool show page displays correctly
- ✅ Owner shows as "Deleted Account" on show page

### 4.3 Test Flags/Bugs Display with Deleted User

**Setup (in Rails console):**
```ruby
user = User.create!(email: "flagger@example.com", username: "flagger", password: "password123")
tool_owner = User.create!(email: "owner2@example.com", username: "owner2", password: "password123")
tool = Tool.create!(user: tool_owner, tool_name: "Flagged Tool", tool_url: "https://example.com", visibility: :public)
flag = Comment.create!(user: user, tool: tool, comment: "This is a flag", comment_type: :flag)
bug = Comment.create!(user: user, tool: tool, comment: "This is a bug", comment_type: :bug)
user.soft_delete!
```

**Browser Test:**
1. Log in as any user
2. Go to `http://localhost:3000/tools/#{tool.id}`
3. Check Flags section
4. Check Bugs section

**Expected Result:**
- ✅ Flags and bugs are displayed
- ✅ Author shows as "Deleted Account" for both
- ✅ Content is still visible

---

## Test 5: Credential Reuse After Deletion

1. **Delete an account** (follow Test 1)
2. **Try to sign up with the same credentials:**
   - Go to `http://localhost:3000/users/sign_up`
   - Enter the same email that was deleted
   - Enter the same username that was deleted
   - Fill in password
   - Click "Sign up"

**Expected Result:**
- ✅ Registration succeeds
- ✅ New account is created with the same email/username
- ✅ Can log in with new account
- ✅ Credentials are immediately available for reuse

---

## Test 6: Complete User Lifecycle

1. **Register new user:**
   - Go to `http://localhost:3000/users/sign_up`
   - Create account with email, username, password
   - Sign up

2. **Create content:**
   - Create a tool
   - Add a comment to a tool
   - Create a list (if applicable)

3. **Delete account:**
   - Go to Account Settings
   - Delete account with password

4. **Verify content is preserved:**
   - Log in as a different user
   - Navigate to the tool you created
   - Verify tool is still visible
   - Verify comment is still visible
   - Verify owner/author shows as "Deleted Account"

5. **Try to reuse credentials:**
   - Go to sign up page
   - Register with the same email/username from deleted account
   - Should succeed

**Expected Result:**
- ✅ Complete lifecycle works
- ✅ All content preserved after deletion
- ✅ Deleted user info shows as "Deleted Account"
- ✅ Credentials can be reused immediately
- ✅ Deleted user cannot log in

---

## Quick Test Checklist

Use this checklist for a quick smoke test:

- [ ] Can delete account via Account Settings
- [ ] User is signed out after deletion
- [ ] Deleted user cannot log in
- [ ] Error message shown when deleted user tries to log in
- [ ] Tools show "Deleted Account" for deleted owners
- [ ] Comments show "Deleted Account" for deleted authors
- [ ] Flags/Bugs show "Deleted Account" for deleted authors
- [ ] Content (tools, comments) is still visible after user deletion
- [ ] Can register new account with deleted user's email/username
- [ ] Password validation works (wrong password prevents deletion)
- [ ] Success message appears after successful deletion

---

## Troubleshooting

### Issue: Deleted user can still log in
**Check:** Verify the user was actually soft deleted (check Rails console: `user.deleted?`)

### Issue: "Deleted Account" not displaying
**Check:** 
- Verify `display_user_name` helper is being used in views
- Check browser console for JavaScript errors
- Verify user is actually deleted

### Issue: Cannot reuse credentials after deletion
**Check:** 
- Verify user was soft deleted (not hard deleted)
- Check Rails console: `User.find_by(email: "your@email.com").deleted?`
- Try signing up again - should work

### Issue: Account deletion doesn't work
**Check:**
- Verify password is correct
- Check browser console for errors
- Verify you're on the correct page (`/account_settings`)
- Check Rails logs for errors

---

## Notes

- All automated tests are in the `test/` directory
- Rails console setup is optional - you can create test data through the UI as well
- Focus on verifying user-facing behavior matches expectations
- If automated tests pass, most technical functionality is working correctly

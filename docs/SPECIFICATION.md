# Application Specification

This document serves as the human-readable specification for the Hacker Tools application. It is maintained alongside development and updated as features are built.

**Last Updated**: 2025-12-11 (Submission System - Phase 1, Week 1 Complete)

## Overview

Server-first Rails 7 + Hotwire app for curating and discussing hacking/engineering tools. Users can publish tools, tag them, group them into lists, discuss via threaded comments, and interact via upvotes/favorites/follows.

### Seed Data Snapshot
- Tool catalog seeded with 34 tools (original set doubled plus security-focused additions from a soft-deleted user).
- Tags expanded to include security, CI/CD, and observability to reflect the richer tool set.
- Lists cover Ruby basics, frontend stack, DevOps essentials, private favorites, a database workbench, and an archived security list owned by a deleted user.
- Comments include threaded discussions on new tools (CI caching strategies, formatting, observability, API clients) plus security flags/bugs contributed by the deleted user to validate soft-delete associations.

## Core Features

### Submission System
- **Status**: Complete (Phase 1, Week 1)
- **Description**: Users submit content (articles, guides, repos, etc.) about tools. Tools are community-owned entities, submissions are user-contributed content.
- **User Stories**:
  - As a user, I want to submit content about a tool so others can discover it.
  - As a user, I want to see my submissions in my dashboard.
  - As a visitor, I want to browse and filter submissions by type, status, and tool.
  - As a user, I want to tag my submissions for better organization.
  - As a user, I want to follow submissions to track updates.
- **Technical Implementation**:
  - Models: `Submission`, `SubmissionTag`, `ListSubmission`
  - Ownership: `Submission` belongs to `User`; `Tool` is community-owned (no user ownership)
  - Submission types: article, guide, documentation, github_repo, etc.
  - Status workflow: pending → processing → completed/failed/rejected
  - Routes: `resources :submissions` with nested comments and member routes for tags/follow
  - URL normalization for duplicate detection (preserves content-identifying query params)
  - Polymorphic comments (can comment on both Tools and Submissions)
- **UI/UX Considerations**:
  - Submission index with filtering (by type, status, tool)
  - Submission show page with comments, flags, bugs, tags
  - Tag management (add/remove tags - owner only)
  - Follow/unfollow functionality
  - Turbo Streams for real-time updates
- **Dependencies**:
  - Devise-authenticated users to create/edit submissions
  - Processing pipeline (Step 2.1+) for automatic enrichment

### Tool Catalog
- **Status**: Updated - Community-Owned
- **Description**: Tools are community-owned top-level entities. Users submit content about tools, they don't own tools.
- **User Stories**:
  - As a visitor, I want to browse tools and see submissions about them.
  - As a visitor, I want to filter tools by tags and lists.
- **Technical Implementation**:
  - Models: `Tool`, `Tag`, `ToolTag`, `List`, `ListTool`
  - Ownership: Tools are community-owned (no user ownership)
  - Visibility/list types modeled as enums on `Tool` and `List`
  - Tagging and list inclusion via join tables
  - Routes: `resources :tools` (index, show, new, create, edit, update, destroy)
  - Active Storage attachments for tool `icon` and `picture`
  - Polymorphic comments (can comment on both Tools and Submissions)
- **UI/UX Considerations**:
  - Use Bootstrap grid/cards; responsive at mobile breakpoints
  - Turbo Streams for live updates when tools are added/edited
- **Dependencies**:
  - Devise-authenticated users to create/edit tools
  - Active Storage optional for icons/pictures

### Engagement & Feedback
- **Status**: In Progress
- **Description**: Users discuss tools and react with upvotes, favorites, follows, and read tracking.
- **User Stories**:
  - As a user, I want to comment on a tool and reply to threads so I can ask questions or provide feedback.
  - As a user, I want to upvote/favorite/follow tools so I can track what matters.
  - As a user, I want to upvote comments so helpful answers are surfaced.
- **Technical Implementation**:
  - Models: `Comment`, `CommentUpvote`, `UserTool`, `Follow` (polymorphic)
  - Threaded comments via `parent_id` on `Comment`
  - Comment types: `comment`, `flag`, `bug`; `solved` marks resolved flags/bugs
  - Tool show page sections: comments (threaded), flags (resolvable), bugs (resolvable)
  - User-tool interaction flags stored on `UserTool`
- **UI/UX Considerations**:
  - Turbo Streams for live comment threads (future)
  - Accessible forms and focus management for replies
  - Inline, collapsible forms for flag/bug submissions
- **Dependencies**:
  - Devise-authenticated users for interactions

## Data Models

### User (Devise)
- **Purpose**: Authenticated account that submits content, creates lists, and participates in discussions.
- **Attributes**:
  - `email` (string, required, unique among active users)
  - `encrypted_password` (string, required)
  - `username` (string, required, unique among active users)
  - `user_type` (integer, enum)
  - `user_status` (integer, enum: `active: 0`, `deleted: 1`)
  - `user_bio` (text)
- **Active Storage**: `avatar` attachment
- **Associations**:
  - `has_many :submissions` (user-contributed content about tools)
  - `has_many :lists`, `has_many :comments`
  - `has_many :user_tools`, `has_many :tool_interactions, through: :user_tools`
  - `has_many :comment_upvotes`
- **Status**: Updated - Removed `has_many :tools`; users no longer own tools, they submit content about tools
- **Validations**: 
  - Presence on username/email
  - Uniqueness on username/email among active users only (allows reuse after deletion)
  - Devise password rules
- **Scopes**:
  - `User.active` - Returns only active users (excludes deleted)
  - `User.deleted` - Returns only deleted users
  - Note: No default scope - associations work with deleted users to preserve historical data
- **Soft Delete**:
  - Account deletion uses soft delete (marks `user_status` as `deleted`)
  - Username and email are anonymized (`deleted_user_#{id}`, `deleted_#{id}@deleted.local`)
  - Deleted users cannot authenticate (blocked via `active_for_authentication?`)
  - Historical data (comments, tools) is preserved with deleted user references
  - Username/email become immediately available for reuse

### Tool
- **Purpose**: Community-owned top-level entity representing any software-related concept, technology, service, or platform. Tools are shared community resources, not user-owned.
- **Attributes**: `tool_name` (string, required), `tool_description` (text), `tool_url` (string), `author_note` (text), `visibility` (integer enum)
- **Active Storage**: `icon`, `picture` attachments
- **Associations**: `has_many :submissions`; `has_many :comments, as: :commentable` (polymorphic); `has_many :tags, through: :tool_tags`; `has_many :lists, through: :list_tools`; `has_many :user_tools`
- **Validations**: Presence on name; visibility enum.
- **Status**: Updated - Removed user ownership; tools are now community-owned entities

### List
- **Purpose**: Curated collection of tools for a user.
- **Attributes**: `list_name` (string, required), `list_type` (integer enum), `visibility` (integer enum: private/public)
- **Associations**: 
  - `belongs_to :user`
  - `has_many :tools, through: :list_tools`
  - `has_many :follows, as: :followable` (polymorphic)
  - `has_many :followers, through: :follows, source: :user`
- **Validations**: Presence on name; uniqueness of name scoped to user; enums on type/visibility.
- **Scopes**: 
  - `public_lists` - Returns only public lists (visibility = public)
  - `recent` - Orders by creation date descending
- **Helper Methods**:
  - `follower_count` - Returns count of users following this list
  - `followed_by?(user)` - Checks if a user is following this list

### Comment
- **Purpose**: Threaded discussion on tools or submissions (polymorphic).
- **Attributes**: `comment` (text, required), `comment_type` (integer enum: comment/flag/bug), `parent_id` (self-referential), `solved` (boolean)
- **Associations**: `belongs_to :commentable, polymorphic: true` (can be Tool or Submission); `belongs_to :user`; `belongs_to :parent, class_name: "Comment", optional: true`; `has_many :replies, class_name: "Comment"`
- **Validations**: Presence on body; presence on type.
- **Status**: Updated - Now polymorphic to support comments on both Tools and Submissions

### Tag
- **Purpose**: Hierarchical classification system for tools with parent-child relationships.
- **Attributes**: `tag_name` (string, required, unique), `tag_description` (text), `tag_type` (integer enum: category/language/framework/library/version/platform/other), `parent_id` (self-referential, optional)
- **Associations**: `has_many :tools, through: :tool_tags`; `belongs_to :parent, class_name: "Tag", optional: true`; `has_many :children, class_name: "Tag"`; `has_many :tool_tags, dependent: :destroy`
- **Validations**: Presence on name (case-insensitive uniqueness); presence on type; circular parent reference prevention
- **Scopes**: `roots` (tags without parent), `by_type` (ordered by type and name), `with_children` (includes children)
- **Helper Methods**: `display_name` (shows parent/child hierarchy), `ancestors` (parent chain), `root?` (checks if no parent)
- **Status**: Complete - Full CRUD with hierarchical display, color-coded by type, add/remove from tools

### ToolTag (join)
- **Purpose**: Many-to-many between tools and tags.
- **Attributes**: `tool_id`, `tag_id`
- **Associations**: `belongs_to :tool`; `belongs_to :tag`
- **Validations**: Uniqueness on `[tool_id, tag_id]`.

### ListTool (join)
- **Purpose**: Tools included in a list.
- **Attributes**: `list_id`, `tool_id`
- **Associations**: `belongs_to :list`; `belongs_to :tool`
- **Validations**: Uniqueness on `[list_id, tool_id]`.

### UserTool (join/state)
- **Purpose**: Per-user interaction state for a tool.
- **Attributes**: `read_at` (datetime), `upvote` (boolean), `favorite` (boolean), foreign keys to user/tool
- **Associations**: `belongs_to :user`; `belongs_to :tool`
- **Validations**: Uniqueness on `[user_id, tool_id]`.
- **Behavior**: Created/touched on tool show (sets `read_at`), toggled via upvote/favorite buttons on home, tools index, and tool show.

### Follow (polymorphic)
- **Purpose**: Unified following system for users, tools, lists, and tags.
- **Attributes**: `user_id`, `followable_type`, `followable_id`
- **Associations**: `belongs_to :user`; `belongs_to :followable, polymorphic: true`
- **Validations**: 
  - Uniqueness on `[user_id, followable_type, followable_id]`
  - `cannot_follow_self` - Prevents users from following themselves (when followable_type is "User")
  - `cannot_follow_own_list` - Prevents users from following their own lists (when followable_type is "List")
- **Behavior**: Replaces tool subscriptions; used for following users/tools/lists/tags.

### Submission
- **Purpose**: User-contributed content about tools. Can be articles, guides, documentation, GitHub repos, etc.
- **Attributes**: 
  - `submission_url` (string, nullable - for future text-only posts)
  - `normalized_url` (string, nullable, unique scoped to user_id)
  - `submission_type` (integer enum: article, guide, documentation, github_repo, etc.)
  - `status` (integer enum: pending, processing, completed, failed, rejected)
  - `author_note` (text - free text description from user)
  - `submission_name` (string - extracted/derived name)
  - `submission_description` (text - extracted description)
  - `metadata` (jsonb - flexible data storage)
  - `duplicate_of_id` (references submissions - for duplicate detection)
  - `processed_at` (datetime - when processing completed)
- **Associations**: 
  - `belongs_to :user` (user who submitted the content)
  - `belongs_to :tool, optional: true` (tool this submission is about)
  - `has_many :submission_tags`; `has_many :tags, through: :submission_tags`
  - `has_many :list_submissions`; `has_many :lists, through: :list_submissions`
  - `has_many :comments, as: :commentable` (polymorphic)
  - `has_many :follows, as: :followable` (polymorphic)
  - `has_many :followers, through: :follows, source: :user`
- **Validations**: 
  - Presence of user
  - URL format validation (when submission_url present)
  - Uniqueness of normalized_url scoped to user_id
- **Scopes**: 
  - `pending`, `completed`, `processing`, `failed`, `rejected` (by status)
  - `recent` (ordered by created_at desc)
  - `by_type(type)` (filter by submission_type)
  - `for_tool(tool)` (filter by tool)
- **Helper Methods**: 
  - `follower_count` - Returns count of users following this submission
  - `duplicate?` - Checks if submission is marked as duplicate
  - `metadata_value(key)` - Retrieves value from metadata JSONB
  - `set_metadata_value(key, value)` - Sets value in metadata JSONB
- **Status**: Complete - Full CRUD with tag management, follow functionality, and polymorphic comments

### SubmissionTag (join)
- **Purpose**: Many-to-many between submissions and tags.
- **Attributes**: `submission_id`, `tag_id`
- **Associations**: `belongs_to :submission`; `belongs_to :tag`
- **Validations**: Uniqueness on `[submission_id, tag_id]`.

### ListSubmission (join)
- **Purpose**: Submissions included in a list.
- **Attributes**: `list_id`, `submission_id`
- **Associations**: `belongs_to :list`; `belongs_to :submission`
- **Validations**: Uniqueness on `[list_id, submission_id]`.

### CommentUpvote (join)
- **Purpose**: User upvotes on comments.
- **Attributes**: `comment_id`, `user_id`
- **Associations**: `belongs_to :comment`; `belongs_to :user`
- **Validations**: Uniqueness on `[comment_id, user_id]`.

## User Flows

### Flow Name
1. [Step 1]
2. [Step 2]
3. [Step 3]

## API Endpoints

### Endpoint Name
- **Method**: GET/POST/PATCH/DELETE
- **Path**: `/path/to/endpoint`
- **Parameters**: [Required/optional params]
- **Response**: [Expected response format]
- **Authentication**: [Required/optional]

## Technical Architecture

### Stack
- **Framework**: Ruby on Rails 7.1+
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Styling**: Bootstrap 5.3, SCSS
- **Background Jobs**: Active Job
- **File Storage**: Active Storage with Cloudinary
- **Real-time**: Turbo Streams / Action Cable

### Design System
- **Border Radius**: 12px (0.75rem) for all interactive elements and content boxes
- **Input/Button Height**: 44px (2.75rem) for consistent touch targets
- **Color Scheme**: Professional palette with primary color #272727
- **Background**: White (#ffffff) for page and content backgrounds
- **Primary Color Usage**: Primary color (#272727) is used as default for:
  - All links (with hover state darkening by 10%)
  - Body text color
  - Shadows (with alpha/opacity for depth - typically 0.1 to 0.15)
  - Navigation links
  - Text elements
- **Hover Animations**: Subtle transform and shadow effects on interactive elements
- **Focus States**: Clear visual indicators with primary color border and shadow
- **Typography**: All heading elements (h1-h6) have zero margins for consistent spacing control
- **Styling Approach**: Bootstrap-first - use Bootstrap classes when applicable before writing custom CSS
- **Implementation**:
  - Bootstrap variables configured in `app/assets/stylesheets/config/_bootstrap_variables.scss` for global theme
  - Global base styles in `app/assets/stylesheets/components/_base.scss` for design system overrides
  - Page-specific styles in `app/assets/stylesheets/pages/` for page-specific needs
  - Component-specific styles in `app/assets/stylesheets/components/` for custom components
  - Bootstrap utility classes used extensively in views for spacing, layout, and responsive behavior
  - Custom CSS only when Bootstrap cannot achieve the desired result
  - All buttons, inputs, and content boxes have consistent 12px rounded corners
  - Navbar explicitly excluded from rounded corners
  - Hover animations on all inputs, textareas, checkboxes, radio buttons, and navigation links
  - Flash messages (alerts) styled with rounded corners and fixed positioning
  - Home page styled with centered container and proper spacing
  - Navbar and offcanvas menu with hover effects and rounded corners
  - Professional, modern appearance with smooth transitions

### Key Patterns
- Server-first architecture
- Fat models, skinny controllers
- Service objects for complex business logic
- Turbo Streams for real-time updates

## Internationalization

- **Default Locale**: English (en)
- **Available Locales**: English (en) - additional locales can be added
- **Translation Files**: `config/locales/`
- **Status**: Complete - All user-facing text is internationalized
- **Implementation**:
  - All views use `t()` helper for translations
  - Navigation, buttons, labels, and messages are localized
  - Application title and page headings use i18n
  - ARIA labels and accessibility text are localized
  - Translation keys organized by feature/domain (navigation, pages, actions, messages, forms, errors)

## Testing Strategy

- **Unit Tests**: Model validations, business logic
- **Request Tests**: Controller actions, HTTP handling
- **System Tests**: End-to-end user flows with Playwright
- **Coverage Goal**: [Target coverage percentage]

## Deployment

- **Platform**: Heroku
- **App Name**: hacker-tools
- **Environment Variables**: [List required env vars]

## Authentication (Devise)

- **Status**: Complete
- **Description**: User authentication system using Devise gem
- **Features**:
  - User registration and login
  - Password reset functionality
  - Email confirmation
  - Account unlock
  - Remember me functionality
  - Soft-deleted users are blocked from authentication
- **Views**: All Devise views styled with consistent design system
  - Sign in (`devise/sessions/new.html.erb`)
  - Sign up (`devise/registrations/new.html.erb`)
  - Edit account (`devise/registrations/edit.html.erb`)
  - Password reset (`devise/passwords/new.html.erb`, `devise/passwords/edit.html.erb`)
  - Email confirmation (`devise/confirmations/new.html.erb`)
  - Account unlock (`devise/unlocks/new.html.erb`)
- **Styling**: All authentication pages use `.devise-container` class with:
  - Centered layout (max-width: 480px)
  - White background with subtle shadow
  - 12px rounded corners
  - Consistent form styling with hover animations
  - Responsive design for mobile devices
- **Internationalization**: All Devise views fully internationalized using Rails i18n

## User Profile

- **Status**: Complete
- **Description**: User profile page and account settings management
- **Features**:
  - Profile display page showing username, avatar, and bio
  - Tabbed interface showing public tools, comments, upvotes, and lists
  - Public lists display with follow/unfollow functionality
  - Account settings with separate sections for different updates
  - Avatar management (upload, delete) - no password required
  - Bio management - no password required
  - Username and email updates - password required
  - Password changes - password required
  - Account soft deletion with confirmation modal
- **Routes**:
  - `GET /u/:username` → `profiles#show` (public profile display page)
  - `POST /u/:username/follow` → `profiles#follow` (follow user)
  - `DELETE /u/:username/unfollow` → `profiles#unfollow` (unfollow user)
  - `GET /dashboard` → `dashboard#show` (private dashboard)
  - `GET /account_settings` → `account_settings#show` (account settings)
  - `PATCH /account_settings/update_avatar` → `account_settings#update_avatar`
  - `PATCH /account_settings/update_bio` → `account_settings#update_bio`
  - `PATCH /account_settings/update_username_email` → `account_settings#update_username_email`
  - `PATCH /account_settings/update_password` → `account_settings#update_password`
  - `DELETE /account_settings/delete_avatar` → `account_settings#delete_avatar`
  - `DELETE /account_settings` → `account_settings#destroy` (soft delete account)
- **Controllers**:
  - `ProfilesController` - Simple controller for profile display
  - `DashboardController` - Private, read-only dashboard slices for the current user
  - `AccountSettingsController` - Custom controller for account management (independent from Devise)
- **Views**:
  - Profile page (`profiles/show.html.erb`) - Read-only profile display with tabbed interface:
    - Posts tab: Public tools created by the user
    - Comments tab: Comments made by the user on public tools
    - Upvotes tab: Public tools upvoted by the user
    - Lists tab: Public lists created by the user with follow/unfollow buttons
  - List card partial (`profiles/_list_card.html.erb`) - Displays list name, tool count, creation date, follower count, and follow button
  - Dashboard (`dashboard/show.html.erb`) - Overview cards (counts) and recent slices for tools, lists, discussions, favorites, follows
  - Account settings (`account_settings/show.html.erb`) - Split into 5 sections:
    1. Avatar update (with delete button)
    2. Bio update
    3. Username and email update
    4. Password change
    5. Account deletion
- **Security**:
  - Avatar and bio updates don't require password (less sensitive)
  - Username, email, and password changes require current password
  - Account deletion requires password confirmation via modal
- **Account Deletion (Soft Delete)**:
  - Uses soft delete: marks user as deleted instead of removing record
  - Anonymizes username and email to free them for immediate reuse
  - Preserves historical data (comments, tools, lists) with deleted user references
  - Signs out user after deletion
  - Deleted users cannot log in (blocked via authentication)
  - Username/email become available for new registrations immediately
- **Lists Management**:
  - Lists can be created, edited, and deleted by their owners
  - Lists have visibility settings (private/public)
  - Public lists are displayed on user profile pages
  - Users can follow/unfollow public lists (except their own)
  - Follow/unfollow actions use Turbo Streams for real-time updates
  - Routes:
    - `POST /lists/:id/follow` → `lists#follow` (follow a public list)
    - `DELETE /lists/:id/unfollow` → `lists#unfollow` (unfollow a list)
  - Turbo Stream template (`lists/follow_update.turbo_stream.erb`) updates follow button and follower count in real time
- **UI/UX**:
  - Profile page shows avatar (or gray placeholder with initial) and no edit CTA (settings moved to nav)
  - Dashboard is a private view; public profile to be added later
  - Account settings organized in card-based sections
  - Each section has its own submit button
  - Confirmation modal for destructive actions (avatar deletion, account deletion)
  - Consistent styling with design system (12px rounded corners, proper spacing)
  - Deleted users display as "Deleted Account" throughout the application
  - List cards on profile page show list name, tool count, creation date, follower count, and follow button
  - Follow buttons only appear for signed-in users viewing lists they don't own

## UI Components

### Navigation
- **Status**: Complete
- **Description**: Responsive navigation bar with mobile offcanvas menu
- **Components**:
  - Main navbar (`shared/_navbar.html.erb`)
  - Navbar items partial (`shared/_navbar_items.html.erb`)
  - Offcanvas menu for mobile devices
- **Links**:
  - Home, Tools, New Tool, Tags, Profile (private), Dashboard (private), Account (account settings), Auth links
- **Behavior**:
  - Dashboard and Account links are distinct from Profile; Profile stays read-only
- **Styling**:
  - Navbar has no rounded corners (as per design system)
  - Navbar links have hover animations (translateY and background color change)
  - Offcanvas menu with rounded corners on left side
  - Mobile hamburger button with hover effects
  - Responsive design for all screen sizes

### Flash Messages
- **Status**: Complete
- **Description**: Alert notifications for user feedback with auto-dismiss functionality
- **Components**: 
  - Flash messages partial (`shared/_flashes.html.erb`)
  - Stimulus controller (`flash_controller.js`) for auto-dismiss
- **Styling**:
  - White background with primary color text (#272727)
  - Bolder borders (2px) to distinguish alert types (info, success, warning, danger)
  - Border colors use Bootstrap color variables (info, success, warning, danger)
  - Shadow uses primary color with alpha (rgba($primary, 0.15))
  - Fixed position (bottom-right on desktop, full-width on mobile)
  - 12px rounded corners
  - Slide-in animation from right on appear
  - Fade-out animation on dismiss
  - Responsive positioning for mobile devices
- **Functionality**:
  - Auto-dismisses after 2 seconds (2000ms)
  - Manual dismiss via close button
  - Smooth animations for both appear and dismiss

### Confirmation Modal
- **Status**: Complete
- **Description**: Reusable confirmation modal for destructive actions (delete, remove, etc.)
- **Components**:
  - Confirmation modal partial (`shared/_confirmation_modal.html.erb`)
  - Stimulus controller (`confirmation_modal_controller.js`) for modal interactions
- **Usage Pattern**:
  - Use for all destructive actions (delete account, delete avatar, delete tool, etc.)
  - Replace browser default `confirm()` dialogs with this modal
  - Provides consistent UX across the application
- **Implementation**:
  - Bootstrap modal with centered dialog
  - Dimmed background overlay
  - Configurable title, message, and button text
  - Supports form submission via `button_to` for DELETE requests
  - Styled with 12px rounded corners consistent with design system
- **Styling**:
  - Modal content has 12px rounded corners
  - Dimmed background (rgba(0, 0, 0, 0.5))
  - Centered modal dialog
  - Consistent button styling with app design system
  - Proper spacing and typography
- **Example Usage**:
  ```erb
  <%= render "shared/confirmation_modal",
      id: "delete-avatar-modal",
      title: "Delete Avatar",
      message: "Are you sure you want to delete your avatar?",
      confirm_text: "Yes, Delete Avatar",
      confirm_class: "btn-danger",
      form_action: delete_avatar_user_registration_path,
      form_method: :delete %>
  ```
- **Current Usage**:
  - Account deletion (`devise/registrations/edit.html.erb`)
  - Avatar deletion (`devise/registrations/edit.html.erb`)

### Home Page
- **Status**: Complete
- **Description**: Landing page organized around discovery-first browsing with multiple search entry points
- **Components**: Home page view (`pages/home.html.erb`)
- **Layout & UX**:
  - Divider under navbar, then an 8-column wide primary search bar (large input + search button)
  - Category toggle bar for `Trending`, `New & Hot`, and `Most Upvoted` lists (JS-ready to switch lists without reload)
  - Each category panel renders up to 10 live tools:
    - Trending: most upvoted in the last 30 days (by `user_tools.upvote`)
    - New & Hot: tools from last 7 days ranked by upvotes
    - Most Upvoted: highest upvotes all time
    - Left (≈5 cols @ ≥md): star, ordinalized position, tool description or fallback, tags (or sample tags), stretched-link to `/tools/:id`
    - Right (≈7 cols @ ≥md): logo stub plus inline upvote button showing “▲ X upvotes”; signed-in users increment inline, guests see an alert to sign in
- **Styling**:
  - Bootstrap grid-first layout, responsive down to mobile
  - Buttons and cards use design-system spacing/shadows with a noticeable hover lift (`card-hover`)
  - Ready to swap placeholder link and logo with real assets/data streams

## Future Considerations

- [Planned features or improvements]
- [Technical debt to address]
- [Scalability considerations]


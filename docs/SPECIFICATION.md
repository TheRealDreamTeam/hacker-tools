# Application Specification

This document serves as the human-readable specification for the Hacker Tools application. It is maintained alongside development and updated as features are built.

**Last Updated**: [Date will be updated as spec evolves]

## Overview

Server-first Rails 7 + Hotwire app for curating and discussing hacking/engineering tools. Users can publish tools, tag them, group them into lists, discuss via threaded comments, and interact via upvotes/favorites/subscriptions.

## Core Features

### Tool Catalog
- **Status**: In Progress
- **Description**: Users publish tools with descriptions, links, and media. Visibility controls allow private/unlisted/public sharing.
- **User Stories**:
  - As a user, I want to create a tool entry with description, icon, and link so others can discover it.
  - As a visitor, I want to browse and filter tools by tags and lists so I can find relevant items quickly.
- **Technical Implementation**:
  - Models: `Tool`, `Tag`, `ToolTag`, `List`, `ListTool`
  - Ownership: `Tool` belongs to `User`
  - Visibility/list types modeled as enums on `Tool` and `List`
  - Tagging and list inclusion via join tables
  - Routes: `resources :tools` (index, show, new, create, edit, update, destroy)
  - Active Storage attachments for tool `icon` and `picture`
  - Creation flow: user supplies URL + author note; name/description/picture can be LLM-generated from URL
- **UI/UX Considerations**:
  - Use Bootstrap grid/cards; responsive at mobile breakpoints
  - Turbo Streams for live updates when tools are added/edited
- **Dependencies**:
  - Devise-authenticated users to create/edit tools
  - Active Storage optional for icons/pictures

### Engagement & Feedback
- **Status**: Planned
- **Description**: Users discuss tools and react with upvotes, favorites, subscriptions, and read tracking.
- **User Stories**:
  - As a user, I want to comment on a tool and reply to threads so I can ask questions or provide feedback.
  - As a user, I want to upvote/favorite/subscribe to tools so I can track what matters.
  - As a user, I want to upvote comments so helpful answers are surfaced.
- **Technical Implementation**:
  - Models: `Comment`, `CommentUpvote`, `UserTool`
  - Threaded comments via `parent_id` on `Comment`
  - User-tool interaction flags stored on `UserTool`
- **UI/UX Considerations**:
  - Turbo Streams for live comment threads
  - Accessible forms and focus management for replies
- **Dependencies**:
  - Devise-authenticated users for interactions

## Data Models

### User (Devise)
- **Purpose**: Authenticated account that owns tools/lists and participates in discussions.
- **Attributes**:
  - `email` (string, required, unique)
  - `encrypted_password` (string, required)
  - `username` (string, required, unique)
  - `user_type` (integer, enum)
  - `user_status` (integer, enum)
  - `user_bio` (text)
- **Active Storage**: `avatar` attachment
- **Associations**:
  - `has_many :tools`, `has_many :lists`, `has_many :comments`
  - `has_many :user_tools`, `has_many :tool_interactions, through: :user_tools`
  - `has_many :comment_upvotes`
- **Validations**: Presence/uniqueness on email/username; Devise password rules.

### Tool
- **Purpose**: A published tool with metadata, owned by a user.
- **Attributes**: `tool_name` (string, required), `tool_description` (text), `tool_url` (string), `author_note` (text), `visibility` (integer enum)
- **Active Storage**: `icon`, `picture` attachments
- **Associations**: `belongs_to :user`; `has_many :comments`; `has_many :tags, through: :tool_tags`; `has_many :lists, through: :list_tools`; `has_many :user_tools`
- **Validations**: Presence on name; visibility enum.

### List
- **Purpose**: Curated collection of tools for a user.
- **Attributes**: `list_name` (string, required), `list_type` (integer enum), `visibility` (integer enum)
- **Associations**: `belongs_to :user`; `has_many :tools, through: :list_tools`
- **Validations**: Presence on name; enums on type/visibility.

### Comment
- **Purpose**: Threaded discussion on a tool.
- **Attributes**: `comment` (text, required), `comment_type` (integer enum), `visibility` (integer enum), `parent_id` (self-referential), `solved` (boolean)
- **Associations**: `belongs_to :tool`; `belongs_to :user`; `belongs_to :parent, class_name: "Comment", optional: true`; `has_many :replies, class_name: "Comment"`
- **Validations**: Presence on body; enums for type/visibility.

### Tag
- **Purpose**: Classification for tools.
- **Attributes**: `tag_name` (string, required), `tag_description` (text), `tag_type` (integer enum), `parent_id` (self-referential)
- **Associations**: `has_many :tools, through: :tool_tags`; `belongs_to :parent, class_name: "Tag", optional: true`; `has_many :children, class_name: "Tag"`
- **Validations**: Presence on name; enum on type.

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
- **Attributes**: `read_at` (datetime), `upvote` (boolean), `favorite` (boolean), `subscribe` (boolean), foreign keys to user/tool
- **Associations**: `belongs_to :user`; `belongs_to :tool`
- **Validations**: Uniqueness on `[user_id, tool_id]`.

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

## UI Components

### Navigation
- **Status**: Complete
- **Description**: Responsive navigation bar with mobile offcanvas menu
- **Components**:
  - Main navbar (`shared/_navbar.html.erb`)
  - Navbar items partial (`shared/_navbar_items.html.erb`)
  - Offcanvas menu for mobile devices
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

### Home Page
- **Status**: Complete
- **Description**: Landing page with welcome content
- **Components**: Home page view (`pages/home.html.erb`)
- **Styling**:
  - Centered container (max-width: 1200px)
  - Proper spacing and typography
  - Responsive padding for mobile devices
  - Heading with zero margins (controlled by container)

## Future Considerations

- [Planned features or improvements]
- [Technical debt to address]
- [Scalability considerations]


# Application Specification

This document serves as the human-readable specification for the Hacker Tools application. It is maintained alongside development and updated as features are built.

**Last Updated**: [Date will be updated as spec evolves]

## Overview

[Brief description of the application's purpose and main functionality]

## Core Features

### Feature 1: [Feature Name]
- **Status**: [Planned / In Progress / Complete]
- **Description**: [What this feature does]
- **User Stories**: 
  - As a [user type], I want to [action] so that [benefit]
- **Technical Implementation**:
  - [Key technical details, models, controllers, routes]
- **UI/UX Considerations**:
  - [Mobile responsiveness, accessibility, user flows]
- **Dependencies**:
  - [Related features or external services]

## Data Models

### Model Name
- **Purpose**: [What this model represents]
- **Attributes**:
  - `attribute_name` (type): [Description]
- **Associations**:
  - [Relationships to other models]
- **Validations**:
  - [Key validation rules]
- **Scopes**:
  - [Common queries]

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
- **Hover Animations**: Subtle transform and shadow effects on interactive elements
- **Focus States**: Clear visual indicators with primary color border and shadow
- **Implementation**:
  - Global base styles in `app/assets/stylesheets/components/_base.scss`
  - Bootstrap variables configured in `app/assets/stylesheets/config/_bootstrap_variables.scss`
  - Page-specific styles in `app/assets/stylesheets/pages/`
  - All buttons, inputs, and content boxes have consistent 12px rounded corners
  - Navbar explicitly excluded from rounded corners
  - Hover animations on all inputs, textareas, checkboxes, and radio buttons
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

## Future Considerations

- [Planned features or improvements]
- [Technical debt to address]
- [Scalability considerations]


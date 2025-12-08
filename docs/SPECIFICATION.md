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

## Future Considerations

- [Planned features or improvements]
- [Technical debt to address]
- [Scalability considerations]

---

## Change Log

### 2024-12-08
- Added: Complete internationalization (i18n) implementation
  - All user-facing text converted to use Rails i18n
  - Translation keys added for navigation, pages, actions, messages, forms, and errors
  - Views updated to use `t()` helper instead of hardcoded strings
  - Application title, navigation menu, buttons, and ARIA labels are now localized
- Updated: `config/locales/en.yml` with comprehensive translation keys
- Updated: Views (`layouts/application.html.erb`, `pages/home.html.erb`, `shared/_navbar.html.erb`, `shared/_flashes.html.erb`) to use i18n


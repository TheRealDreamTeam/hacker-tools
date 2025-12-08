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
- **Available Locales**: [List locales]
- **Translation Files**: `config/locales/`

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

### [Date]
- Added: [Feature or change]
- Updated: [What was modified]
- Removed: [What was deprecated]


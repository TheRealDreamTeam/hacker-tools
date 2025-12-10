# Inline Styles and Scripts Documentation

This document explains which inline styles and scripts exist in the codebase and why they must remain inline (or have been moved to proper locations).

## Moved to Proper Locations

### ✅ `app/views/pages/home.html.erb`

**JavaScript Block (Lines 144-309)** - **MOVED**
- **Location**: Moved to `app/javascript/controllers/home_page_controller.js`
- **Reason**: Large JavaScript block (165+ lines) handling category toggles, search debouncing, and upvote functionality
- **Implementation**: Converted to Stimulus controller with proper data attributes
- **Status**: ✅ Completed

**CSS Style Block (Lines 311-355)** - **MOVED**
- **Location**: Moved to `app/assets/stylesheets/pages/_home.scss`
- **Reason**: Page-specific styles for card hovers, side banners, and mobile article card layouts
- **Status**: ✅ Completed

## Inline Styles That Must Stay

### ✅ `app/views/layouts/application.html.erb` (Lines 56-115)

**FOUC Prevention Styles** - **MUST STAY INLINE**
- **Reason**: These styles must be in the `<head>` section and execute **before** external stylesheets load to prevent Flash of Unstyled Content (FOUC)
- **Critical Timing**: The styles hide the body until JavaScript is ready, preventing visible content flash
- **Performance**: Inline styles in `<head>` are parsed immediately, while external stylesheets load asynchronously
- **Fallback**: Includes animation fallback if JavaScript fails to load
- **Status**: ✅ Must remain inline

### ✅ Dynamic Content Styles (Various Files)

**Background Images and Gradients** - **ACCEPTABLE INLINE**
- **Files**: 
  - `app/views/pages/home.html.erb` - Background images for ad banners and article cards
  - `app/views/tags/index.html.erb` - Dynamic tag type colors
  - `app/views/tools/index.html.erb` - Font size adjustments
  - `app/views/pages/_tool_card.html.erb` - Image sizing
  - `app/views/account_settings/_avatar_section.html.erb` - Avatar sizing
  - `app/views/profiles/show.html.erb` - Avatar sizing

**Reason**: These inline styles are for:
1. **Dynamic content** - Background images from external URLs (Unsplash)
2. **Dynamic colors** - Tag type colors computed server-side (`tag_type_color` helper)
3. **Image sizing** - Object-fit and dimensions for user-uploaded avatars
4. **Responsive adjustments** - Font sizes that may vary based on content

**Alternative Consideration**: Some of these could be moved to CSS classes, but:
- External image URLs are easier to manage inline
- Dynamic server-side computed values (colors) are more maintainable inline
- Image sizing for user content is often better handled inline for flexibility

**Status**: ✅ Acceptable to remain inline (dynamic/server-computed content)

## Summary

- **JavaScript**: All JavaScript blocks have been moved to Stimulus controllers
- **CSS Blocks**: All CSS style blocks have been moved to proper stylesheet files
- **Inline Styles in Head**: FOUC prevention styles must remain inline for performance
- **Inline Style Attributes**: Dynamic content styles are acceptable and remain inline

## Best Practices Going Forward

1. **JavaScript**: Always use Stimulus controllers for page-specific JavaScript
2. **CSS**: Use page-specific stylesheets (`app/assets/stylesheets/pages/`) for page-specific styles
3. **Inline Styles**: Only use inline styles for:
   - Critical FOUC prevention (in `<head>`)
   - Dynamic server-computed values (colors, URLs)
   - User-generated content sizing (avatars, images)
4. **Avoid**: Inline styles for static styling - use CSS classes instead


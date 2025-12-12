# Lessons Learned - Submission System Implementation

**Last Updated**: 2025-12-11  
**Related**: `docs/SUBMISSION_PROCESS_IMPROVEMENT.md`, `docs/PHASE_1_IMPLEMENTATION_PLAN.md`

## Overview

This document captures key lessons learned during the implementation of the submission-centric architecture (Phase 1, Week 1). These patterns and practices should be applied to future development.

## Database & Model Patterns

### 1. Database Indexes Must Match Validation Scopes

**Problem**: Created a unique index on `normalized_url` globally, but validation was scoped to `user_id`. This caused database constraint violations when different users tried to submit the same URL.

**Solution**: Changed from global unique index to composite unique index:
```ruby
# ❌ Wrong: Global unique index
add_index :submissions, :normalized_url, unique: true

# ✅ Correct: Composite unique index matching validation scope
add_index :submissions, [:normalized_url, :user_id], unique: true, 
          where: "normalized_url IS NOT NULL"
```

**Lesson**: Always ensure database constraints match Active Record validations. If a validation is scoped (e.g., `uniqueness: { scope: :user_id }`), the database index must also be scoped.

**Pattern**: When adding uniqueness validations with scopes, create composite indexes that match the scope.

### 2. URL Normalization Must Preserve Content-Identifying Parameters

**Problem**: Initial URL normalization was too aggressive, removing all query parameters. This meant `https://news.ycombinator.com/item?id=43331847` and `https://news.ycombinator.com/item?id=99999999` would normalize to the same URL, even though they're different articles.

**Solution**: Preserve content-identifying query parameters (like `id`, `v`, `status`) while removing only tracking/analytics parameters:
```ruby
# Preserve content-identifying params
tracking_params = %w[utm_source utm_medium utm_campaign utm_term utm_content ref source fbclid gclid]
clean_params = query_params.except(*tracking_params)
```

**Lesson**: URL normalization should balance duplicate prevention with the need to distinguish unique content. Content-identifying parameters (IDs, versions, status) should be preserved.

**Pattern**: 
- Remove: Tracking/analytics params (`utm_*`, `ref`, `fbclid`, `gclid`)
- Preserve: Content-identifying params (`id`, `v`, `version`, `status`, `page`)
- Always: Remove fragments, normalize host (remove www), lowercase, remove trailing slash

### 3. Test Factories Need Unique Sequences for Uniqueness Validations

**Problem**: Factory was generating the same `submission_url` for multiple submissions, causing uniqueness validation failures.

**Solution**: Use `sequence` to ensure unique values:
```ruby
# ❌ Wrong: Same URL for all submissions
factory :submission do
  submission_url { "https://example.com/article" }
end

# ✅ Correct: Unique URL for each submission
factory :submission do
  sequence(:submission_url) { |n| "https://example.com/article-#{n}" }
end
```

**Lesson**: When models have uniqueness validations, factories must generate unique values using `sequence`.

**Pattern**: Always use `sequence` for attributes with uniqueness validations in factories.

## Controller & Routing Patterns

### 4. Turbo Stream Redirects Require `status: :see_other`

**Problem**: Turbo Stream redirects weren't working - page didn't navigate after form submission.

**Solution**: Use `status: :see_other` for Turbo Stream redirects:
```ruby
# ✅ Correct: Turbo Stream redirect with status
format.turbo_stream { redirect_to @submission, status: :see_other, notice: t("submissions.create.success") }
```

**Lesson**: Turbo Stream format requires explicit status code for redirects. `:see_other` (303) is the correct status for redirects after POST.

**Pattern**: Always use `status: :see_other` when redirecting in Turbo Stream format.

### 5. Locale-Scoped Routes Require Explicit `id:` Parameter in Tests

**Problem**: Tests were failing with `ActionController::UrlGenerationError` because Rails was interpreting the submission object as the locale parameter.

**Solution**: Use explicit `id:` parameter in path helpers:
```ruby
# ❌ Wrong: Rails interprets object as locale
get submission_path(@submission)

# ✅ Correct: Explicit id parameter
get submission_path(id: @submission.id)
```

**Lesson**: When routes are locale-scoped (`scope "(:locale)"`), path helpers need explicit parameter names to avoid ambiguity.

**Pattern**: Always use `id:` parameter when calling path helpers with locale-scoped routes in tests.

### 6. Authorization Redirects Should Go to Index, Not Show Page

**Problem**: When unauthorized users tried to edit/delete submissions, they were redirected to the submission show page, which they could still access.

**Solution**: Redirect unauthorized users to the index page:
```ruby
# ❌ Wrong: Redirects to show page (still accessible)
redirect_to @submission, alert: t("submissions.unauthorized")

# ✅ Correct: Redirects to index (safer)
redirect_to submissions_path, alert: t("submissions.flash.unauthorized")
```

**Lesson**: Authorization failures should redirect to a safe location (index page) rather than the resource show page.

**Pattern**: Always redirect unauthorized users to the index page, not the resource show page.

### 7. Follow Actions Should Toggle, Not Just Create

**Problem**: Follow action only created follows, never removed them. Users couldn't unfollow.

**Solution**: Implement toggle behavior:
```ruby
# ✅ Correct: Toggle follow/unfollow
def follow
  follow_record = current_user.follows.find_by(followable: @submission)
  
  if follow_record
    follow_record.destroy
    flash[:notice] = t("submissions.follow.unfollowed")
  else
    current_user.follows.create!(followable: @submission)
    flash[:notice] = t("submissions.follow.success")
  end
end
```

**Lesson**: Follow/unfollow actions should toggle state, not just create. This provides better UX and matches user expectations.

**Pattern**: Follow actions should check if follow exists, then create or destroy accordingly.

## Polymorphic Associations

### 8. Polymorphic Associations Require Careful Test Updates

**Problem**: When making `Comment` polymorphic (from `belongs_to :tool` to `belongs_to :commentable`), all tests needed updates.

**Solution**: 
- Update factories to use `commentable:` instead of `tool:`
- Update test assertions to use `comment.commentable` instead of `comment.tool`
- Update path helpers to handle polymorphic routing

**Lesson**: Polymorphic associations require comprehensive test updates across all test files that reference the association.

**Pattern**: When introducing polymorphic associations:
1. Update all factories
2. Update all test assertions
3. Update all path helpers/routing logic
4. Update all views that reference the association

## Testing Patterns

### 9. Test Assertions Should Match Controller Behavior

**Problem**: Tests expected redirects to `submissions_path` but controller redirected to `@submission` (show page).

**Solution**: Update tests to match actual controller behavior, or update controller to match expected behavior (we chose the latter - redirect to index).

**Lesson**: Tests should accurately reflect controller behavior. If tests fail, either fix the controller or fix the test expectations - choose based on what makes sense for the feature.

**Pattern**: When tests fail due to redirect mismatches, consider which behavior is correct (usually the test expectation is correct, but verify).

### 10. Reload Associations After Turbo Stream Updates

**Problem**: After adding/removing tags via Turbo Stream, the association wasn't refreshed, causing stale data.

**Solution**: Reload the association before rendering:
```ruby
@submission.tags.reload
```

**Lesson**: After modifying associations (especially through join tables), reload the association to ensure fresh data for Turbo Stream updates.

**Pattern**: Always reload associations after modifying them when preparing Turbo Stream responses.

## Architecture Patterns

### 11. Submission-Centric vs Tool-Centric Architecture

**Key Insight**: The shift from "Tool" centric to "Submission" centric fundamentally changes ownership:
- **Tools**: Community-owned entities (no user ownership)
- **Submissions**: User-contributed content about tools (user-owned)

**Impact**:
- Removed `belongs_to :user` from `Tool` model
- Added `belongs_to :user` to `Submission` model
- Updated all views, controllers, and tests
- Changed user dashboard from "My Tools" to "My Submissions"

**Lesson**: Architectural shifts require comprehensive updates across models, controllers, views, tests, and documentation.

**Pattern**: When making architectural changes:
1. Update models first (associations, validations)
2. Update migrations
3. Update factories
4. Update controllers
5. Update views
6. Update tests
7. Update documentation

## Code Quality Patterns

### 12. Comprehensive Test Coverage Catches Issues Early

**Lesson**: Writing comprehensive controller tests (35 tests covering all actions, authorization, edge cases) caught multiple issues:
- Follow action not toggling
- Authorization redirects going to wrong page
- Database index mismatch with validation
- Path helper issues with locale-scoped routes

**Pattern**: Write tests as you implement features, not after. Tests should cover:
- Happy paths
- Authorization (owner vs non-owner, signed in vs not)
- Edge cases (duplicates, invalid data)
- Error handling

### 13. Migration Strategy for Schema Changes

**Lesson**: When making significant schema changes (removing user ownership from tools, adding submissions):
1. Create new tables first (submissions)
2. Create join tables (submission_tags, list_submissions)
3. Migrate existing data if needed
4. Remove old associations last
5. Test migrations on empty database first

**Pattern**: Plan migrations carefully, test on empty database, then test with data.

## Summary

These lessons learned should be applied to future development:

1. **Database constraints must match validations** - Always create composite indexes for scoped uniqueness
2. **URL normalization must be content-aware** - Preserve content-identifying parameters
3. **Test factories need unique sequences** - Use `sequence` for uniqueness validations
4. **Turbo Stream redirects need status codes** - Use `status: :see_other`
5. **Locale-scoped routes need explicit parameters** - Use `id:` in path helpers
6. **Authorization redirects should be safe** - Redirect to index, not show page
7. **Follow actions should toggle** - Check existence, then create or destroy
8. **Polymorphic associations need comprehensive updates** - Update all references
9. **Test assertions should match behavior** - Fix controller or tests based on what's correct
10. **Reload associations after modifications** - Ensure fresh data for Turbo Streams
11. **Architectural changes are comprehensive** - Update models, controllers, views, tests, docs
12. **Write tests as you go** - Catch issues early with comprehensive coverage
13. **Plan migrations carefully** - Test on empty database first

These patterns should be documented in `.cursorrules` and applied consistently across the codebase.


# Form Error Display Guidelines

## Preferred Approach

**CRITICAL**: Forms should display errors **only at the field level** using Bootstrap's `invalid-feedback` pattern. Do NOT use alert banners at the top of forms.

### Why Field-Level Errors?

1. **Better UX**: Errors appear directly next to the problematic field, making it clear which field needs correction
2. **No Duplication**: Avoids showing the same error message twice (once in an alert, once under the field)
3. **Consistent Pattern**: Matches Bootstrap's validation styling and accessibility best practices
4. **Clearer Context**: Users can immediately see which field has an issue without scanning a list

## Implementation Pattern

### For Custom Forms (form_with)

```erb
<div class="mb-3">
  <%= f.label :field_name, "Field Label", class: "form-label" %>
  <%= f.text_field :field_name, class: "form-control #{'is-invalid' if model.errors[:field_name].any?}" %>
  <% if model.errors[:field_name].any? %>
    <div class="invalid-feedback">
      <% model.errors[:field_name].each do |error| %>
        <div><%= error %></div>
      <% end %>
    </div>
  <% end %>
</div>
```

**Key Points:**
- Add `is-invalid` class to the input when errors exist
- Display errors in a `div.invalid-feedback` directly below the input
- Loop through all errors for the field (some fields can have multiple errors)
- Place the `invalid-feedback` div immediately after the input, before any `form-text` hints

### For Simple Form Forms

Simple Form automatically handles field-level errors via the `simple_form_bootstrap` configuration. **Do NOT use `f.error_notification`** as it creates duplicate error messages.

**Correct:**
```erb
<%= simple_form_for(@model) do |f| %>
  <%# No f.error_notification - errors appear at field level automatically %>
  <%= f.input :field_name %>
<% end %>
```

**Incorrect:**
```erb
<%= simple_form_for(@model) do |f| %>
  <%= f.error_notification %>  <%# REMOVE THIS - creates duplicate errors %>
  <%= f.input :field_name %>
<% end %>
```

## Examples in Codebase

### ✅ Correct Implementation

**Account Settings - Password Section:**
```erb
<div class="mb-3">
  <%= f.label :password, t("forms.password"), class: "form-label" %>
  <%= f.password_field :password, class: "form-control #{'is-invalid' if user.errors[:password].any?}", autocomplete: "new-password" %>
  <% if user.errors[:password].any? %>
    <div class="invalid-feedback">
      <% user.errors[:password].each do |error| %>
        <div><%= error %></div>
      <% end %>
    </div>
  <% end %>
</div>
```

**Delete Account Modal:**
```erb
<div class="mt-3">
  <%= f.label :password, t("account_settings.destroy.password_label"), class: "form-label" %>
  <%= f.password_field :password, class: "form-control #{'is-invalid' if @user.errors[:delete_account_password].any?}", ... %>
  <% if @user.errors[:delete_account_password].any? %>
    <div class="invalid-feedback">
      <% @user.errors[:delete_account_password].each do |error| %>
        <div><%= error %></div>
      <% end %>
    </div>
  <% end %>
</div>
```

### ❌ Anti-Pattern (Do NOT Use)

**Alert Banner at Top:**
```erb
<% if model.errors.any? %>
  <div class="alert alert-danger">
    <% model.errors.full_messages.each do |error| %>
      <div><%= error %></div>
    <% end %>
  </div>
<% end %>
```

**Simple Form with error_notification:**
```erb
<%= simple_form_for(@model) do |f| %>
  <%= f.error_notification %>  <%# Creates duplicate errors %>
  <%= f.input :field_name %>
<% end %>
```

## Forms Fixed in This Project

All forms have been updated to follow this pattern:

1. **Account Settings Forms:**
   - ✅ `_password_section.html.erb` - Field-level errors only
   - ✅ `_username_email_section.html.erb` - Field-level errors only
   - ✅ `_avatar_section.html.erb` - Field-level errors only
   - ✅ `_bio_section.html.erb` - Field-level errors only
   - ✅ Delete account modal - Field-level errors only

2. **Simple Form Forms:**
   - ✅ `tools/_form.html.erb` - No `error_notification` (already removed)
   - ✅ `comments/_form.html.erb` - No `error_notification` (never had it)
   - ✅ `devise/registrations/new.html.erb` - Removed `error_notification`
   - ✅ `devise/registrations/edit.html.erb` - Removed `error_notification`
   - ✅ `devise/sessions/new.html.erb` - No `error_notification` (never had it)
   - ✅ `devise/passwords/new.html.erb` - Removed `error_notification`
   - ✅ `devise/passwords/edit.html.erb` - Removed `error_notification` (kept `f.full_error` for hidden field)
   - ✅ `devise/confirmations/new.html.erb` - Removed `error_notification` (kept `f.full_error` for hidden field)
   - ✅ `devise/unlocks/new.html.erb` - Removed `error_notification` (kept `f.full_error` for hidden field)

## Bootstrap Validation Classes

- **`is-invalid`**: Applied to the input field when errors exist
- **`invalid-feedback`**: Container for error messages, displayed below the input
- **`is-valid`**: Applied to the input field when validation passes (optional, for positive feedback)

## Accessibility

Field-level errors are more accessible because:
- Screen readers can associate errors directly with the field
- Users can see the error context immediately
- No need to navigate between alert and field

## When to Use Alert Banners

Alert banners (`alert alert-danger`) should **only** be used for:
- **Flash messages** (success/error notifications after form submission)
- **System-level errors** (not validation errors)
- **Non-field-specific errors** (e.g., "Account has been deleted")
- **Hidden field errors** (using `f.full_error` for hidden fields like tokens)

**Never use alert banners for form validation errors on visible fields** - these should always be field-level.

### Exception: Hidden Field Errors

For hidden fields (like `reset_password_token`, `confirmation_token`, `unlock_token`), you may use `f.full_error` to display system-level errors since these fields cannot display field-level errors:

```erb
<%= f.input :reset_password_token, as: :hidden %>
<%= f.full_error :reset_password_token %>  <%# OK for hidden fields %>
```

This is acceptable because:
- The field is hidden and cannot display field-level errors
- These are typically system-level errors (invalid/expired tokens)
- The error is not duplicated elsewhere

## Migration Checklist

When updating existing forms:

- [ ] Remove any `alert alert-danger` banners that display validation errors
- [ ] Remove `f.error_notification` from Simple Form forms
- [ ] Add `is-invalid` class conditionally to each input field
- [ ] Add `invalid-feedback` div below each input field
- [ ] Test form validation to ensure errors display correctly
- [ ] Verify no duplicate error messages appear


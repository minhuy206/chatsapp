# Fix: Undefined Variable `current` in Conversation Creation

## Issue Summary
**Error**: `undefined local variable or method 'current' for an instance of #<Class:0x00000001251fddf0>`
**Context**: Failed to create conversation during Turbo Stream response rendering
**Root Cause**: Missing `current` local variable when rendering `_conversation_item.html.erb` partial

## Root Cause Analysis

### 1. Error Location
The error occurred in the `_conversation_item.html.erb` partial at line 2:
```erb
class="conversation-item group relative p-3 rounded-lg cursor-pointer hover:bg-gray-700 transition-colors <%= 'bg-gray-700' if current %>"
```

### 2. Missing Parameter
The partial expects a `current` local variable to determine if the conversation item should have active styling (`bg-gray-700` class).

### 3. Source of Issue
In `app/controllers/home_controller.rb`, the `create` action renders the partial via Turbo Stream without passing the required `current` local variable:

**Before (Broken)**:
```ruby
turbo_stream.prepend("conversation-list", partial: "shared/conversation_item", locals: { conversation: @conversation }),
```

## Fix Applied

### Updated Home Controller
**After (Fixed)**:
```ruby
turbo_stream.prepend("conversation-list", partial: "shared/conversation_item", locals: { conversation: @conversation, current: false }),
```

### Reasoning
- New conversations are never "current" when first created since they appear at the top of the sidebar
- Setting `current: false` provides the expected `false` value for the conditional styling
- This maintains consistency with other renders of the same partial

## Verification

### 1. Syntax Check
```bash
ruby -c app/controllers/home_controller.rb
# Output: Syntax OK
```

### 2. Consistent Usage
All other renders of `_conversation_item.html.erb` properly pass the `current` parameter:

**Home Index View**:
```erb
<%= render partial: "shared/conversation_item", locals: { conversation: conversation, current: false } %>
```

**Conversation Show View**:
```erb
<%= render partial: "shared/conversation_item", locals: {
  conversation: conversation,
  current: conversation.id == @conversation.id
} %>
```

## Impact

### Before Fix
- Creating new conversations would fail with undefined variable error
- Users unable to start new chats
- Turbo Stream responses would break

### After Fix
- Conversation creation works seamlessly
- New conversations appear in sidebar with correct styling
- Turbo Stream updates function as expected
- No visual regression - new conversations correctly show as non-active

## Prevention
To prevent similar issues:

1. **Parameter Validation**: Ensure all required local variables are passed to partials
2. **Default Values**: Consider using `local_assigns.fetch(:current, false)` for optional parameters
3. **Testing**: Add integration tests for Turbo Stream responses
4. **Code Review**: Verify all partial renders include required locals

## Technical Details

### Partial Structure
The `_conversation_item.html.erb` partial uses the `current` variable to:
- Apply active styling (`bg-gray-700`) when `current` is `true`
- Show default styling when `current` is `false`
- Provide visual feedback for the currently selected conversation

### Use Cases
- `current: true` - Currently viewing this conversation
- `current: false` - All other conversations in the sidebar list

## Files Modified
- `app/controllers/home_controller.rb` - Added missing `current: false` parameter
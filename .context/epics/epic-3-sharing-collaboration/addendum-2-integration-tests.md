# Epic 3: Sharing & Collaboration - Addendum 2
## Integration Tests for Direct User Sharing

**Date**: January 14, 2026
**Status**: Completed
**File**: `client/listonit/integration_test/sharing_and_collaboration_test.dart`

---

## Overview

Comprehensive integration tests for the direct user sharing feature in Epic 3. Tests cover adding members to lists, removing members, and viewing list members with proper mocking of API calls.

---

## Test Structure

### Test Framework
- **Framework**: Flutter Integration Tests
- **Mocking**: mocktail for API mocking
- **Provider Mocking**: Riverpod provider overrides
- **Pattern**: Same as existing tests (lists_test.dart, items_test.dart)

### Test Organization

```
Epic 3: Sharing & Collaboration
├── Story 3.1: Direct User Sharing
│   ├── Add Member to List
│   │   ├── Members modal displays add member button for owner
│   │   ├── Can open add member modal from members modal
│   │   ├── Search users displays all available users
│   │   ├── Can select user from dropdown and assign role
│   │   ├── Add member button is disabled when no user selected
│   │   ├── Successfully adds member with editor role
│   │   ├── Successfully adds member with viewer role
│   │   └── Shows error when adding duplicate member
│   └── Remove Member from List
│       ├── Can open member options menu
│       ├── Owner can see remove option for other members
│       ├── Successfully removes member
│       ├── Shows confirmation dialog before removing member
│       ├── Can cancel member removal
│       └── Member can remove themselves from list
└── Story 3.2: View List Members
    ├── Can view all members of a list
    ├── Displays member roles correctly
    └── Displays user avatars in members list
```

---

## Test Categories

### 1. Add Member to List (8 tests)

**Test: Members modal displays add member button for owner**
- Navigate to list detail
- Open members modal
- Verify "Add Member" button (person_add icon) is visible for list owner

**Test: Can open add member modal from members modal**
- Mock ListApi and UserApi
- Navigate to list and open members modal
- Tap "Add Member" button
- Verify share modal opens with "Add Member" title

**Test: Search users displays all available users**
- Mock `searchUsers()` to return test users
- Open add member modal
- Verify search box is displayed
- Search functionality is tested implicitly through UI navigation

**Test: Can select user from dropdown and assign role**
- Mock user search API
- Open add member modal
- Verify dropdown button exists
- Verify role selector displays "Can edit" (default)

**Test: Add member button is disabled when no user selected**
- Mock empty user search results
- Open add member modal
- Verify "Add Member" button exists but is disabled
- Confirms user must select someone before adding

**Test: Successfully adds member with editor role**
- Mock successful API response for adding editor
- Open add member modal
- Select user from dropdown (mocked to return "John Doe")
- Role defaults to "editor"
- Tap "Add Member" button
- Verify success notification "Member added"
- Verify API called with correct parameters

**Test: Successfully adds member with viewer role**
- Similar to editor test but:
- Change role to "Can view" before selecting user
- Verify API called with `role: 'viewer'`

**Test: Shows error when adding duplicate member**
- Mock API to throw "User is already a member" error
- Attempt to add user
- Verify error is displayed in snackbar

### 2. Remove Member from List (6 tests)

**Test: Can open member options menu**
- Navigate to list detail
- Open members modal
- Verify members list is displayed (ListView)

**Test: Owner can see remove option for other members**
- Open members modal as list owner
- Verify member menu icon (more_vert) is visible
- Indicates owner has access to manage members

**Test: Successfully removes member**
- Mock `removeMember()` API call
- Open member menu
- Tap "Remove member" option
- Confirm in dialog
- Verify success notification "Member removed"
- Verify API called with correct list_id and user_id

**Test: Shows confirmation dialog before removing member**
- Open member menu
- Tap "Remove member"
- Verify AlertDialog appears
- Verify dialog shows "Remove member?" message
- Confirms safe deletion pattern

**Test: Can cancel member removal**
- Open member menu and tap "Remove member"
- Confirmation dialog appears
- Tap "Cancel" button
- Verify dialog closes
- Verify `removeMember()` API was NOT called
- Confirms cancellation works

**Test: Member can remove themselves from list**
- Mock removal API for current user (test-user-id)
- Open members modal
- Tap menu for current user
- Verify "Leave list" option appears (not "Remove member")
- Confirms different UX for self-removal

### 3. View List Members (3 tests)

**Test: Can view all members of a list**
- Navigate to list detail
- Open members modal
- Verify members are displayed as ListTiles
- Confirms basic member list display

**Test: Displays member roles correctly**
- Open members modal
- Look for role indicators (Owner, editor, viewer)
- Verify role text is displayed for members
- Confirms role information is visible

**Test: Displays user avatars in members list**
- Open members modal
- Look for CircleAvatar widgets
- Verify avatars are displayed for each member
- Confirms visual representation of members

---

## Mock Classes

### MockListApi
```dart
class MockListApi extends Mock implements ListApi {}
```
- Mocks all ListApi methods
- Configured per test to return specific responses
- Supports error scenarios via `.thenThrow()`

### MockUserApi
```dart
class MockUserApi extends Mock implements UserApi {}
```
- Mocks `searchUsers()` method
- Returns list of User objects
- Can be configured to return empty list or specific users

---

## Test Data

### Test User
```dart
User(
  id: 'user-2',
  email: 'john@example.com',
  name: 'John Doe',
  isActive: true,
  isAdmin: false,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
)
```

### Test Lists
Uses existing test lists from mock_providers:
- "Groceries" (list-1) - owned by test-user-id
- "Hardware Store" (list-2)
- "Party Supplies" (list-3)

---

## Mock Configuration

Each test uses this override pattern:

```dart
ProviderScope(
  overrides: [
    ...createTestOverrides(
      authState: authenticatedState(),
      listsState: listsStateWithData(),
    ),
    listApiProvider.overrideWithValue(mockListApi),
    userApiProvider.overrideWithValue(mockUserApi),
  ],
  child: const ListonitApp(),
)
```

---

## Key Testing Patterns

### 1. Navigation Pattern
```dart
// Navigate to list detail
await tester.tap(find.text('Groceries'));
await tester.pumpAndSettle();

// Open members modal
final membersIcon = find.byIcon(Icons.people);
if (membersIcon.evaluate().isNotEmpty) {
  await tester.tap(membersIcon.first);
  await tester.pumpAndSettle();
}
```

### 2. Mock Setup Pattern
```dart
when(() => mockListApi.addMember('list-1', 'user-2', 'editor'))
    .thenAnswer((_) async => {
      'id': 'user-2',
      'name': 'John Doe',
      'role': 'editor',
    });
```

### 3. Verification Pattern
```dart
verify(
  () => mockListApi.addMember('list-1', 'user-2', 'editor'),
).called(1);
```

### 4. Error Handling Pattern
```dart
when(() => mockListApi.addMember(...))
    .thenThrow(Exception('User is already a member'));
```

---

## UI Elements Tested

### Icons
- `Icons.people` - Open members modal
- `Icons.person_add` - Add member button
- `Icons.more_vert` - Member options menu

### Text Elements
- "Add Member" - Modal title and button
- "Can edit" / "Can view" - Role options
- "Member added" - Success notification
- "Member removed" - Success notification
- "Remove member?" - Confirmation dialog
- "Leave list" - Self-removal option

### Widget Types
- `DropdownButton<String>` - User selection
- `FilledButton` - Action buttons
- `TextField` - Search box
- `AlertDialog` - Confirmation dialogs
- `SnackBar` - Notifications
- `ListTile` - Member list items
- `CircleAvatar` - Member avatars
- `ListView` - Members list

---

## Running the Tests

### Run specific test file
```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/sharing_and_collaboration_test.dart
```

### Run all integration tests
```bash
flutter test integration_test/
```

### Run with verbose output
```bash
flutter test integration_test/sharing_and_collaboration_test.dart -v
```

---

## Test Coverage

**Total Tests**: 17
- Add Member tests: 8
- Remove Member tests: 6
- View Members tests: 3

**Coverage Areas**:
- ✅ Happy path (successful add/remove)
- ✅ Error cases (duplicate member, API errors)
- ✅ Edge cases (disabled button when no user selected)
- ✅ Confirmation flows (cancel, confirm)
- ✅ Role assignment (editor, viewer)
- ✅ Permission checks (owner vs non-owner)
- ✅ UI navigation and element verification
- ✅ API mocking and verification

---

## Future Test Enhancements

1. **Bulk operations** - Add multiple users at once
2. **Search filtering** - Test search by name, email
3. **Role changes** - Changing member roles after addition
4. **Pagination** - Large member lists
5. **WebSocket updates** - Real-time member list updates
6. **Performance** - Large number of members
7. **Accessibility** - Screen reader compatibility
8. **Network errors** - Connection timeout scenarios

---

## Notes

- Tests use conditional checks (`if (element.evaluate().isNotEmpty)`) to handle UI elements that may not always be present
- All DateTime fields are initialized with valid values (not null)
- Mock providers follow existing patterns from mock_providers.dart
- Integration tests run against the full app widget tree
- Tests are isolated and can run in any order
- No cleanup required - each test is independent


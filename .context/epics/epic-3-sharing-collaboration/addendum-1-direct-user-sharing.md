# Epic 3: Sharing & Collaboration - Addendum 1
## Direct User Sharing Implementation

**Date**: January 14, 2026
**Status**: Completed
**Overview**: Replaced share link-based sharing with direct user selection sharing

---

## What Changed

### Previous System (Share Links)
- Users generated unique shareable links
- Recipients clicked links to join lists
- Role (editor/viewer) was set per link, not per user
- Anonymous joining possible with just the link

### New System (Direct User Sharing)
- List owners select specific users from the platform roster
- No shareable links - direct invitation only
- Each user gets their own role assignment
- Sharing only works between registered platform users

---

## User Workflow

### For List Owners

1. **Open Members Modal**
   - Navigate to a list they own
   - Click the members icon/button

2. **Add New Members**
   - Click "Add Member" button (person_add icon) in the header
   - Opens the new share modal

3. **Search for Users**
   - Type in search box to find users by name
   - Search is performed as they type
   - Results are filtered to show only non-members

4. **Select User and Role**
   - Choose a single user from the dropdown
   - Set access level: "Can edit" (editor) or "Can view" (viewer)
   - Click "Add Member" to share

5. **Confirmation**
   - User appears in members list
   - Members list refreshes automatically
   - Toast notification confirms success

### For Recipients

- Receive lists when the owner adds them directly
- No links to click or tokens to enter
- Automatic access based on their user ID and assigned role

---

## Technical Architecture

### Backend Changes

#### New Endpoints

**`GET /users/search`**
- Returns all active platform users
- Optional query parameter `q` for filtering by name
- Response: List of `UserResponse` objects
- Requires authentication

**`POST /lists/{list_id}/members`**
- Adds a specific user to a list
- Request body: `{ user_id: string, role: "editor" | "viewer" }`
- Response: `MemberInfo` object with user details
- Only list owner can call
- Validates:
  - User exists
  - User is not already a member
  - Caller is list owner

#### Removed Endpoints

- `POST /lists/{list_id}/link` - Create share link
- `POST /lists/{list_id}/link/regenerate` - Regenerate token
- `DELETE /lists/{list_id}/link` - Revoke link
- `POST /join/{token}` - Join via share link

#### Database Changes

**ShoppingList Model** - Removed fields:
- `share_token` (str, unique, nullable)
- `share_token_role` (str)
- `share_token_enabled` (bool)

#### Services

**ListService.add_member()** - New method
```python
def add_member(
    self,
    list_id: str,
    target_user_id: str,
    role: str,
    current_user_id: str
) -> MemberInfo:
    # Validates owner permission
    # Validates user exists
    # Validates user not already member
    # Creates ListMember entry
    # Returns member info
```

### Frontend Changes

#### New Components/Files

**`lib/features/auth/data/user_api.dart`**
- New API client for user operations
- `searchUsers(query: String)` - Fetch users with optional name filter
- Provider: `userApiProvider`

#### Modified Components

**`lib/features/lists/presentation/widgets/share_link_modal.dart`** - Complete redesign
- Title: "Add Member" (was "Share List")
- Search box: Real-time user search by name
- User dropdown: Single user selection
- Shows only non-member users (filters by members list)
- Role selector: "Can edit" / "Can view"
- "Add Member" button: Triggers `listApi.addMember()`
- Auto-refresh of members list after adding
- Uses new `userSearchProvider` (FutureProvider)

**`lib/features/lists/presentation/widgets/members_modal.dart`** - Minor updates
- Added "Add Member" button (person_add icon)
- Only visible to list owners
- Opens share modal when clicked
- Positioned in header next to close button

**`lib/features/lists/data/list_api.dart`** - Updated
- Removed: `createShareLink()`, `regenerateShareLink()`, `revokeShareLink()`, `joinViaShareLink()`
- Added: `addMember(listId, userId, role)` - POST to `/lists/{list_id}/members`

#### New Providers

**`userSearchProvider`** - FutureProvider.family
- Type: `FutureProvider.family<List<User>, String>`
- Triggers: When search query changes
- Returns: Filtered list of users matching search
- Used in: share_link_modal.dart

---

## Data Flow

### Adding a Member

```
User (Owner)
    ↓
[Members Modal] Click "Add Member"
    ↓
[Share Modal] Opens
    ↓
[Search Users] Type name → userSearchProvider fetches /users/search
    ↓
[User Dropdown] Select user from results
    ↓
[Role Selector] Choose editor or viewer
    ↓
[Add Member Button] Click
    ↓
[listApi.addMember] POST /lists/{id}/members
    ↓
[Backend] Validates & creates ListMember
    ↓
[Response] MemberInfo returned
    ↓
[Auto-refresh] membersProvider invalidated
    ↓
[UI Update] Modal closes, members list updates
    ↓
[Confirmation] Toast notification shown
```

---

## Key Features

✅ **Direct User Targeting**
- No more anonymous links
- Specific users get access, not "anyone with the link"

✅ **Search Functionality**
- Find users by display name
- Real-time filtering as user types

✅ **Role Assignment per User**
- Each user can have different roles
- Change roles independently via members modal

✅ **Automatic Filtering**
- Already-added members filtered from dropdown
- Prevents duplicate additions

✅ **Owner-Only Access**
- Add member button only visible to list owner
- Backend validates owner permission

✅ **Real-time Updates**
- Riverpod invalidation refreshes members list
- No manual refresh needed

✅ **User-Friendly UI**
- Simple dropdown selection
- Clear role descriptions
- Confirmation feedback

---

## API Contracts

### GET /users/search

**Query Parameters**
```
q (optional): string - Search query for user name
```

**Response**
```json
[
  {
    "id": "user-uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "is_active": true,
    "is_admin": false,
    "created_at": "2026-01-01T00:00:00",
    "updated_at": "2026-01-14T00:00:00"
  }
]
```

### POST /lists/{list_id}/members

**Request Body**
```json
{
  "user_id": "target-user-uuid",
  "role": "editor" // or "viewer"
}
```

**Response (201 Created)**
```json
{
  "id": "user-id",
  "name": "John Doe",
  "avatar": null,
  "role": "editor",
  "created_at": "2026-01-14T12:00:00"
}
```

**Error Responses**
- `404 Not Found` - List not found, user not found
- `400 Bad Request` - User already member
- `403 Forbidden` - Only owner can add members

---

## Removed Code

### Backend
- Share link schemas: `ShareLinkCreate`, `ShareLinkResponse`, `JoinLinkResponse`
- Share link methods in ListService
- Share token fields from ShoppingList model

### Frontend
- `createShareLink()`, `regenerateShareLink()`, `revokeShareLink()`, `joinViaShareLink()` from ListApi
- share_link_provider.dart (orphaned, not removed to avoid breaking other code)

---

## Future Enhancements

Potential improvements for future iterations:

1. **Bulk Invite** - Add multiple users at once
2. **Email Notifications** - Notify users when added to lists
3. **Pending Invitations** - Show sent but unaccepted invites
4. **Invite Expiration** - Limit invitation validity period
5. **User Groups** - Share with groups instead of individuals
6. **Invite Links** - Hybrid approach with expiring links
7. **Activity Log** - Track who added whom and when

---

## Testing Considerations

**Manual Testing Checklist**
- [ ] Owner can view all platform users
- [ ] Owner can search users by name
- [ ] Non-members appear in dropdown, members are filtered
- [ ] Adding a user with editor role works
- [ ] Adding a user with viewer role works
- [ ] Error handling for duplicate adds
- [ ] Error handling for non-existent users
- [ ] Members list updates immediately after adding
- [ ] Non-owner cannot see "Add Member" button
- [ ] Search is case-insensitive
- [ ] Empty search returns all users

**API Testing**
- [ ] GET /users/search returns all active users
- [ ] GET /users/search?q=name filters correctly
- [ ] POST /lists/{id}/members requires authentication
- [ ] POST /lists/{id}/members validates owner permission
- [ ] POST /lists/{id}/members validates user exists
- [ ] POST /lists/{id}/members prevents duplicate members
- [ ] Response contains correct member info

---

## Breaking Changes

⚠️ **This is a breaking change** - Share links will no longer work

- Existing share links are invalidated
- Users cannot join via old links anymore
- All users with access must be re-added manually by list owners
- Migration script may be needed for existing shared lists

---

## Documentation

- Backend API docs updated in `/API.md`
- Frontend Riverpod providers documented in code
- UI patterns follow Material Design guidelines


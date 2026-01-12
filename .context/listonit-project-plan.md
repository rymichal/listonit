# Listonit - System Design & Project Planner

## AI Session System Prompt

```
You are building "Listonit", a collaborative shopping list application. Listonit is a Flutter mobile app with a FastAPI backend that enables users to create, manage, and share shopping lists with real-time collaboration features.

CORE MISSION: Build a modern, performant shopping list app that helps users save time through intuitive list management and real-time sharing with family and friends.

TECH STACK:
- Mobile: Flutter (iOS & Android).  Located at /client/listonit
- Backend: FastAPI (Python 3.11+).  Located at /backend
- Database: PostgreSQL with SQLAlchemy ORM
- Real-time: WebSockets for live sync
- Cache: Redis for sessions and real-time pub/sub
- Auth: JWT with refresh tokens

ARCHITECTURE PRINCIPLES:
1. Offline-first mobile experience with local SQLite and sync queue
2. Real-time collaboration via WebSocket connections
3. RESTful API with WebSocket for live updates
4. Event-driven architecture for list changes
5. Multi-tenant data isolation

MVP SCOPE (What we ARE building):
- List CRUD with colors and icons
- Simplified items (name, quantity, unit, note, checked status)
- Real-time sharing and collaboration
- Push notifications for shared list changes
- Sorting (alphabetical, custom drag-and-drop, chronological)
- Dark mode and accessibility
- Offline support with sync
- User auth (email/password, social login)

NOT IN MVP (Future enhancements):
- Smart suggestions and shopping history
- Product catalog
- Item images
- Item pricing and budget tracking
- Categories and category sorting
- Multi-language support (English only for MVP)
- Web/PWA version (mobile only for MVP)

When implementing features, always consider:
- Offline capability and sync conflict resolution
- Real-time updates across shared list members
- Performance with large lists (1000+ items)
- Accessibility (screen readers, high contrast)
```

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [System Architecture](#2-system-architecture)
3. [Data Models](#3-data-models)
4. [Epic 1: Core List Management](#epic-1-core-list-management)
5. [Epic 2: Item Management](#epic-2-item-management)
6. [Epic 3: Sharing & Collaboration](#epic-3-sharing--collaboration)
7. [Epic 4: Organization & Sorting](#epic-4-organization--sorting)
8. [Epic 5: User Experience Enhancements](#epic-5-user-experience-enhancements)
9. [Epic 6: Cross-Platform & Sync](#epic-6-cross-platform--sync)
10. [API Specification](#api-specification)
11. [Implementation Phases](#implementation-phases)
12. [Future Enhancements](#future-enhancements)

---

## 1. Product Overview

### What is Listonit?

Listonit is a collaborative shopping list application designed to streamline grocery shopping for individuals and families. It combines intuitive list creation with powerful real-time collaboration features, allowing family members and roommates to create, share, and manage shopping lists together seamlessly.

### Key Value Propositions

1. **Collaborative Shopping**: Real-time shared lists with instant sync across all family members
2. **Offline-First**: Full functionality without internet, syncs automatically when back online
3. **Simple & Fast**: Quick item entry with minimal friction, no unnecessary complexity
4. **Organized Lists**: Sort items alphabetically, by custom order, or by recency
5. **Cross-Device Sync**: Seamless experience across iOS and Android devices

### Target Users

- Families managing household shopping
- Roommates splitting grocery duties
- Individuals wanting organized shopping lists
- Anyone wanting shareable, collaborative lists

### Feature Summary (MVP)

| Category | Features |
|----------|----------|
| List Management | Unlimited lists, duplicate, archive, custom colors/icons |
| Item Features | Name, quantity, unit, notes, checked status |
| Collaboration | Real-time sharing, notifications, co-editing |
| Organization | Sort by alphabetical, custom order, chronological |
| UX | Dark mode, offline support, accessibility |
| Sync | Real-time WebSocket sync, offline queue, conflict resolution |

---

## 2. System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│                      Flutter Mobile                              │
│                      (iOS/Android)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │    HTTPS/WSS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        API GATEWAY                               │
│                    (FastAPI + Uvicorn)                          │
├─────────────────────────────────────────────────────────────────┤
│  REST Endpoints  │  WebSocket Hub  │  Auth Middleware           │
└────────┬─────────┴────────┬────────┴────────┬───────────────────┘
         │                  │                 │
         ▼                  ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                               │
├───────────────┬───────────────┬─────────────────────────────────┤
│ List Service  │ Item Service  │ Share Service                   │
└───────┬───────┴───────┬───────┴───────┬─────────────────────────┘
        │               │               │
        ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│        PostgreSQL          │           Redis                    │
│        (Primary DB)        │       (Cache/PubSub)               │
└────────────────────────────┴────────────────────────────────────┘
```

### Flutter App Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # MaterialApp configuration
│   ├── routes.dart              # Navigation routes
│   └── theme.dart               # Light/Dark themes
├── core/
│   ├── constants/               # App constants
│   ├── errors/                  # Exception handling
│   ├── network/                 # HTTP client, interceptors
│   ├── storage/                 # Local SQLite, SharedPrefs
│   └── utils/                   # Helpers, extensions
├── features/
│   ├── auth/
│   │   ├── data/                # Repositories, data sources
│   │   ├── domain/              # Entities, use cases
│   │   └── presentation/        # Screens, widgets, state
│   ├── lists/
│   ├── items/
│   ├── sharing/
│   └── settings/
├── shared/
│   ├── widgets/                 # Reusable components
│   └── providers/               # Global state
└── l10n/                        # Localization files (English only for MVP)
```

### FastAPI Backend Structure

```
backend/
├── main.py                      # FastAPI app entry
├── config.py                    # Settings management
├── api/
│   ├── v1/
│   │   ├── endpoints/
│   │   │   ├── auth.py
│   │   │   ├── lists.py
│   │   │   ├── items.py
│   │   │   └── sharing.py
│   │   └── router.py
│   └── deps.py                  # Dependency injection
├── core/
│   ├── security.py              # JWT, password hashing
│   ├── websocket.py             # WS connection manager
│   └── events.py                # Event bus
├── models/                      # SQLAlchemy models
├── schemas/                     # Pydantic schemas
├── services/                    # Business logic
└── repositories/                # Data access layer
```

---

## 3. Data Models

### Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│     User     │       │     List     │       │     Item     │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │◄──────│ owner_id(FK) │       │ id (PK)      │
│ email        │       │ id (PK)      │◄──────│ list_id (FK) │
│ password     │       │ name         │       │ name         │
│ name         │       │ color        │       │ quantity     │
│ avatar_url   │       │ icon         │       │ unit         │
│ created_at   │       │ is_archived  │       │ note         │
│ updated_at   │       │ sort_mode    │       │ is_checked   │
└──────────────┘       │ created_at   │       │ checked_at   │
       │               │ updated_at   │       │ checked_by   │
       │               └──────────────┘       │ sort_index   │
       │                      │               │ created_by   │
       ▼                      │               │ created_at   │
┌──────────────┐              │               │ updated_at   │
│  ListMember  │◄─────────────┘               └──────────────┘
├──────────────┤
│ id (PK)      │
│ list_id (FK) │
│ user_id (FK) │
│ role         │
│ joined_at    │
└──────────────┘
```

### Core Database Schema

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    avatar_url TEXT,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Lists table
CREATE TABLE lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    color VARCHAR(7) DEFAULT '#4CAF50',
    icon VARCHAR(50) DEFAULT 'shopping_cart',
    is_archived BOOLEAN DEFAULT FALSE,
    sort_mode VARCHAR(20) DEFAULT 'custom', -- alphabetical, custom, chronological
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- List members (sharing)
CREATE TABLE list_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID REFERENCES lists(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'editor', -- owner, editor, viewer
    notifications_enabled BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(list_id, user_id)
);

-- Items
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID REFERENCES lists(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit VARCHAR(20),
    note TEXT,
    is_checked BOOLEAN DEFAULT FALSE,
    checked_at TIMESTAMP,
    checked_by UUID REFERENCES users(id),
    sort_index INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Pending invitations
CREATE TABLE pending_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID REFERENCES lists(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'editor',
    token VARCHAR(64) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_lists_owner ON lists(owner_id);
CREATE INDEX idx_lists_archived ON lists(owner_id, is_archived);
CREATE INDEX idx_items_list ON items(list_id);
CREATE INDEX idx_items_checked ON items(list_id, is_checked);
CREATE INDEX idx_items_sort ON items(list_id, sort_index);
CREATE INDEX idx_list_members_user ON list_members(user_id);
CREATE INDEX idx_list_members_list ON list_members(list_id);
CREATE INDEX idx_pending_invites_token ON pending_invites(token);
CREATE INDEX idx_pending_invites_email ON pending_invites(email);
```

---

## Epic 1: Core List Management

### Context for AI Session

```
EPIC: Core List Management
GOAL: Implement the foundational list CRUD operations that form the backbone of Listonit.

Users should be able to:
- Create unlimited shopping lists with custom names, colors, and icons
- View all their lists in a clean, organized interface
- Edit list properties (rename, change color/icon)
- Delete lists with confirmation
- Duplicate entire lists with all items
- Archive lists for later reference
- Restore archived lists

TECHNICAL REQUIREMENTS:
- Lists are stored both locally (SQLite) and remotely (PostgreSQL)
- Offline list creation must sync when connectivity returns
- List updates trigger real-time notifications to shared members
- Support optimistic UI updates with rollback on failure

FLUTTER STATE MANAGEMENT: Use Riverpod for list state
API ENDPOINTS: RESTful CRUD at /api/v1/lists
```

### Story 1.1: Create New List

**Description**: Users can create a new shopping list with a name, optional color, and icon.

**Acceptance Criteria**:
- Tapping "+" opens create list modal
- Name field is required (min 1, max 100 chars)
- Color picker with 12 preset colors + custom hex
- Icon picker with 20 common shopping icons
- "Create" button disabled until name entered
- New list appears immediately (optimistic UI)
- Show error toast if sync fails, offer retry

**Technical Notes**:
```python
# FastAPI endpoint
@router.post("/lists", response_model=ListResponse)
async def create_list(
    list_data: ListCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    list_obj = List(
        owner_id=current_user.id,
        name=list_data.name,
        color=list_data.color or "#4CAF50",
        icon=list_data.icon or "shopping_cart"
    )
    db.add(list_obj)
    db.commit()

    # Auto-add owner as member
    member = ListMember(
        list_id=list_obj.id,
        user_id=current_user.id,
        role="owner"
    )
    db.add(member)
    db.commit()

    return list_obj
```

```dart
// Flutter - List creation
class ListNotifier extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  Future<void> createList(String name, {String? color, String? icon}) async {
    final tempId = uuid.v4();
    final optimisticList = ShoppingList(
      id: tempId,
      name: name,
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isLocal: true,
    );

    // Optimistic update
    state = AsyncValue.data([...state.value!, optimisticList]);

    try {
      final response = await _api.createList(name: name, color: color, icon: icon);
      // Replace temp with real
      state = AsyncValue.data(
        state.value!.map((l) => l.id == tempId ? response : l).toList()
      );
      await _localDb.upsertList(response);
    } catch (e) {
      // Queue for sync if offline
      if (e is NetworkException) {
        await _syncQueue.enqueue(SyncAction.createList, optimisticList);
      } else {
        // Rollback
        state = AsyncValue.data(
          state.value!.where((l) => l.id != tempId).toList()
        );
        throw e;
      }
    }
  }
}
```

### Story 1.2: View All Lists

**Description**: Users see all their lists (owned + shared) on the home screen.

**Acceptance Criteria**:
- Lists displayed as cards in a scrollable grid/list
- Each card shows: name, color accent, icon, item count, last updated
- Shared lists show avatar stack of members
- Pull-to-refresh fetches latest from server
- Empty state with illustration and "Create your first list" CTA
- Loading skeleton while fetching

**Technical Notes**:
```python
@router.get("/lists", response_model=List[ListWithMeta])
async def get_lists(
    include_archived: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(List).join(ListMember).filter(
        ListMember.user_id == current_user.id
    )

    if not include_archived:
        query = query.filter(List.is_archived == False)

    lists = query.order_by(List.updated_at.desc()).all()

    # Enrich with item counts and member info
    result = []
    for lst in lists:
        item_count = db.query(Item).filter(
            Item.list_id == lst.id,
            Item.is_checked == False
        ).count()

        members = db.query(User).join(ListMember).filter(
            ListMember.list_id == lst.id
        ).limit(5).all()

        result.append(ListWithMeta(
            **lst.__dict__,
            unchecked_count=item_count,
            members=[MemberPreview(id=m.id, name=m.name, avatar=m.avatar_url) for m in members]
        ))

    return result
```

### Story 1.3: Edit List Properties

**Description**: Users can rename lists and change their color/icon.

**Acceptance Criteria**:
- Long-press or menu icon opens edit options
- Inline rename with auto-save on blur
- Color/icon pickers identical to create flow
- Changes sync immediately
- Show "Saving..." indicator briefly

### Story 1.4: Delete List

**Description**: Users can permanently delete lists they own.

**Acceptance Criteria**:
- Delete option in list menu (owners only)
- Confirmation dialog: "Delete [List Name]? This will remove the list for all members."
- Shared members see "Leave list" instead
- Soft delete (30-day recovery window server-side)
- Undo snackbar for 5 seconds

### Story 1.5: Duplicate List

**Description**: Users can create a copy of any list including all items.

**Acceptance Criteria**:
- "Duplicate" option in list menu
- New list named "[Original] (Copy)"
- All items copied (unchecked state)
- Sharing NOT copied (new list is private)
- Navigate to new list after creation

### Story 1.6: Archive/Restore Lists

**Description**: Users can archive lists for later reference without deleting.

**Acceptance Criteria**:
- "Archive" option in list menu
- Archived lists hidden from main view
- "View Archived" option in settings/filter
- "Restore" action on archived lists
- Archived lists still accessible to shared members

---

## Epic 2: Item Management

### Context for AI Session

```
EPIC: Item Management
GOAL: Implement item CRUD with essential metadata support.

Each item has:
- Name (required)
- Quantity (numeric, default 1)
- Unit (dropdown: pcs, kg, lb, oz, L, gal, dozen, pack, etc.)
- Note (free text for brand, size, reminders)
- Checked status (with timestamp and who checked)
- Sort index (for custom ordering)

INTERACTIONS:
- Quick add: Type name, press enter (minimal friction)
- Inline edit: Tap any field to modify
- Check off: Tap or swipe
- Bulk actions: Multi-select for delete/check

OFFLINE REQUIREMENTS:
- All item operations work offline
- Conflict resolution: Last-write-wins with merge for non-conflicting fields
```

### Story 2.1: Add Item (Quick Mode)

**Description**: Users can rapidly add items by typing names.

**Acceptance Criteria**:
- Text input always visible at top/bottom of list
- Pressing enter adds item immediately
- Item appears with default quantity (1)
- Input clears, ready for next item
- Support comma-separated batch add: "milk, eggs, bread"

**Technical Notes**:
```dart
// Quick add controller
class QuickAddController extends StateNotifier<String> {
  final ItemsNotifier _itemsNotifier;

  QuickAddController(this._itemsNotifier) : super('');

  Future<void> submitItems(String input, String listId) async {
    if (input.trim().isEmpty) return;

    // Split by commas for batch add
    final itemNames = input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final name in itemNames) {
      await _itemsNotifier.addItem(
        listId: listId,
        name: name,
        quantity: 1,
      );
    }

    state = ''; // Clear input
  }
}
```

### Story 2.2: Add Item with Details

**Description**: Users can add items with quantity, unit, and notes.

**Acceptance Criteria**:
- "Expand" icon on quick add reveals full form
- Fields: Name, Quantity + Unit, Note
- Quantity has +/- steppers and direct input
- Unit dropdown with common options
- Note is multiline text (max 500 chars)
- "Add" button (or keyboard "Done")

**Technical Notes**:
```dart
class ItemDetailForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Name field
        TextField(
          decoration: InputDecoration(labelText: 'Item name'),
          onChanged: (v) => ref.read(itemFormProvider.notifier).setName(v),
        ),

        // Quantity row
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => ref.read(itemFormProvider.notifier).decrementQty(),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                controller: _qtyController,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => ref.read(itemFormProvider.notifier).incrementQty(),
            ),

            // Unit dropdown
            DropdownButton<String>(
              value: ref.watch(itemFormProvider).unit,
              items: ['pcs', 'kg', 'lb', 'oz', 'L', 'gal', 'dozen', 'pack']
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => ref.read(itemFormProvider.notifier).setUnit(v),
            ),
          ],
        ),

        // Note field
        TextField(
          decoration: InputDecoration(labelText: 'Note (optional)'),
          maxLines: 2,
          maxLength: 500,
          onChanged: (v) => ref.read(itemFormProvider.notifier).setNote(v),
        ),
      ],
    );
  }
}
```

### Story 2.3: Edit Item Inline

**Description**: Users can modify any item property directly in the list.

**Acceptance Criteria**:
- Tap item name → edit name inline
- Tap quantity → number input with +/- steppers
- Tap to expand item → reveal all fields
- Swipe right → quick check off
- Changes save on blur (debounced 500ms)
- Show subtle "Saved" indicator

### Story 2.4: Check/Uncheck Items

**Description**: Users mark items as purchased during shopping.

**Acceptance Criteria**:
- Checkbox or swipe-right gesture to check
- Checked items: strikethrough text, move to bottom
- Uncheck: tap or swipe again
- Record: checked_at timestamp, checked_by user
- Animation: satisfying check mark
- Option: "Check off by swipe" toggle in settings

**Technical Notes**:
```python
@router.patch("/items/{item_id}/check")
async def toggle_check(
    item_id: UUID,
    checked: bool,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    # Verify access
    if not has_list_access(db, current_user.id, item.list_id):
        raise HTTPException(403, "Access denied")

    item.is_checked = checked
    item.checked_at = datetime.utcnow() if checked else None
    item.checked_by = current_user.id if checked else None
    item.updated_at = datetime.utcnow()
    db.commit()

    # Broadcast to list members
    await broadcast_list_update(
        item.list_id,
        {"type": "item_checked", "item_id": str(item_id), "checked": checked}
    )

    return item
```

### Story 2.5: Delete Items

**Description**: Users can remove items from lists.

**Acceptance Criteria**:
- Swipe left to reveal delete button
- Long-press to select, then bulk delete
- Confirmation for bulk delete (>3 items)
- Undo snackbar for 5 seconds
- Deleted items removed from UI immediately

### Story 2.6: Bulk Item Actions

**Description**: Users can perform actions on multiple items at once.

**Acceptance Criteria**:
- Long-press item to enter selection mode
- Checkboxes appear on all items
- "Select All" option
- Actions toolbar: Delete, Check All, Uncheck All
- Exit selection mode on action complete or back

---

## Epic 3: Sharing & Collaboration

### Context for AI Session

```
EPIC: Sharing & Collaboration
GOAL: Enable real-time collaborative list management between users.

SHARING MODEL:
- Lists can be shared with unlimited users
- Roles: Owner (full control), Editor (add/edit/delete items), Viewer (read-only)
- Share via email invitation or shareable link
- Link sharing can be disabled by owner

REAL-TIME SYNC:
- WebSocket connection per active list
- Broadcast all changes instantly
- Show typing indicators when someone is adding
- Show presence (who's viewing the list now)
- Handle reconnection gracefully

NOTIFICATIONS:
- Push notification when shared list is modified
- Configurable per-list notification settings
- In-app notification center
```

### Story 3.1: Share List via Email

**Description**: List owners can invite others by email.

**Acceptance Criteria**:
- "Share" button in list menu/header
- Email input with validation
- Role selector: Editor (default), Viewer
- "Invite" sends email with app link
- Invited user sees list after signing up/in
- Show pending invites with "Resend" option

**Technical Notes**:
```python
@router.post("/lists/{list_id}/invite")
async def invite_member(
    list_id: UUID,
    invite: InviteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    background_tasks: BackgroundTasks
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can invite")

    # Check if user exists
    invitee = db.query(User).filter(User.email == invite.email).first()

    if invitee:
        # Direct add
        member = ListMember(
            list_id=list_id,
            user_id=invitee.id,
            role=invite.role
        )
        db.add(member)
        db.commit()

        # Send notification
        background_tasks.add_task(
            send_share_notification, invitee.email, lst.name, current_user.name
        )
    else:
        # Create pending invite
        invite_token = secrets.token_urlsafe(32)
        pending = PendingInvite(
            list_id=list_id,
            email=invite.email,
            role=invite.role,
            token=invite_token,
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        db.add(pending)
        db.commit()

        # Send invite email
        background_tasks.add_task(
            send_invite_email, invite.email, lst.name, current_user.name, invite_token
        )

    return {"status": "invited"}
```

### Story 3.2: Share List via Link

**Description**: Generate a shareable link for easy list access.

**Acceptance Criteria**:
- "Get Link" option in share menu
- Toggle: "Anyone with link can [Edit/View]"
- Copy link button
- Link format: https://listonit.app/join/[token]
- Owner can revoke/regenerate link
- New users via link become Editors by default

### Story 3.3: Manage List Members

**Description**: Owners can view and manage who has access.

**Acceptance Criteria**:
- Member list shows: avatar, name, role, joined date
- Owner can change member roles
- Owner can remove members
- Non-owners see "Leave list" option
- Show pending invites separately

### Story 3.4: Real-Time Sync

**Description**: All list changes sync instantly across devices.

**Acceptance Criteria**:
- Item added by User A appears on User B's device in <1 second
- No manual refresh needed
- Offline changes sync on reconnect
- Conflict resolution: merge non-conflicting, last-write-wins for conflicts
- Visual indicator: "Syncing..." during update

**Technical Notes**:
```python
# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[UUID, List[WebSocket]] = defaultdict(list)

    async def connect(self, websocket: WebSocket, list_id: UUID, user_id: UUID):
        await websocket.accept()
        self.active_connections[list_id].append(websocket)

        # Announce presence
        await self.broadcast(list_id, {
            "type": "user_joined",
            "user_id": str(user_id),
            "timestamp": datetime.utcnow().isoformat()
        }, exclude=websocket)

    async def disconnect(self, websocket: WebSocket, list_id: UUID, user_id: UUID):
        self.active_connections[list_id].remove(websocket)
        await self.broadcast(list_id, {
            "type": "user_left",
            "user_id": str(user_id)
        })

    async def broadcast(self, list_id: UUID, message: dict, exclude: WebSocket = None):
        for connection in self.active_connections[list_id]:
            if connection != exclude:
                await connection.send_json(message)

manager = ConnectionManager()

@router.websocket("/ws/lists/{list_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    list_id: UUID,
    token: str = Query(...)
):
    user = verify_ws_token(token)
    if not user or not has_list_access(user.id, list_id):
        await websocket.close(code=4003)
        return

    await manager.connect(websocket, list_id, user.id)

    try:
        while True:
            data = await websocket.receive_json()
            # Handle incoming messages (typing indicators, etc.)
            if data["type"] == "typing":
                await manager.broadcast(list_id, {
                    "type": "user_typing",
                    "user_id": str(user.id),
                    "user_name": user.name
                }, exclude=websocket)
    except WebSocketDisconnect:
        await manager.disconnect(websocket, list_id, user.id)
```

```dart
// Flutter WebSocket client
class ListSyncService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  void connect(String listId, String token) {
    final uri = Uri.parse('wss://api.listonit.app/ws/lists/$listId?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        _handleMessage(data);
      },
      onDone: () => _reconnect(listId, token),
      onError: (e) => _reconnect(listId, token),
    );
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'item_added':
        ref.read(itemsProvider.notifier).addFromServer(Item.fromJson(data['item']));
        break;
      case 'item_updated':
        ref.read(itemsProvider.notifier).updateFromServer(Item.fromJson(data['item']));
        break;
      case 'item_checked':
        ref.read(itemsProvider.notifier).setChecked(data['item_id'], data['checked']);
        break;
      case 'user_typing':
        ref.read(typingUsersProvider.notifier).setTyping(data['user_id'], data['user_name']);
        break;
    }
  }
}
```

### Story 3.5: Push Notifications

**Description**: Users receive notifications when shared lists change.

**Acceptance Criteria**:
- Notification when: item added, item checked, member joined/left
- Notification shows: "[User] added [item] to [list]"
- Tap notification opens relevant list
- Per-list notification toggle
- Respect device "Do Not Disturb"
- Badge count on app icon

### Story 3.6: Typing Indicators

**Description**: Show when someone is adding items to a shared list.

**Acceptance Criteria**:
- "[Name] is typing..." appears below input
- Multiple typers: "[Name1] and [Name2] are typing..."
- Disappears after 3 seconds of inactivity
- Subtle animation (pulsing dots)

---

## Epic 4: Organization & Sorting

### Context for AI Session

```
EPIC: Organization & Sorting
GOAL: Help users organize lists for efficient shopping.

SORT MODES:
1. Alphabetical (A-Z) - Simple alphabetical sort
2. Custom - User-defined order via drag-and-drop
3. Chronological - Most recently added first (default)

CHECKED ITEMS:
- Always appear at bottom
- Can be hidden via toggle
- Bulk clear checked items

NO CATEGORIES IN MVP - sorting is flat list only.
```

### Story 4.1: Alphabetical Sort

**Description**: Items sorted A-Z by name.

**Acceptance Criteria**:
- Simple alphabetical sort
- Case-insensitive
- Flat list (no grouping)
- Toggle between A-Z and Z-A
- Sort preference saved per list

**Technical Notes**:
```dart
enum SortMode { alphabetical, custom, chronological }

extension ItemListSorting on List<Item> {
  List<Item> sorted(SortMode mode, {bool ascending = true}) {
    final unchecked = where((i) => !i.isChecked).toList();
    final checked = where((i) => i.isChecked).toList();

    switch (mode) {
      case SortMode.alphabetical:
        unchecked.sort((a, b) => ascending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortMode.custom:
        unchecked.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
        break;
      case SortMode.chronological:
        unchecked.sort((a, b) => ascending
            ? b.createdAt.compareTo(a.createdAt)  // newest first
            : a.createdAt.compareTo(b.createdAt));
        break;
    }

    // Checked items always at bottom, sorted by checked time
    checked.sort((a, b) => b.checkedAt!.compareTo(a.checkedAt!));

    return [...unchecked, ...checked];
  }
}
```

### Story 4.2: Custom Sort (Drag & Drop)

**Description**: Users can manually reorder items.

**Acceptance Criteria**:
- Long-press and drag to reorder
- Drag handle icon for accessibility
- Visual feedback during drag (elevation, opacity)
- Order persists across sessions
- Reset to default (chronological) option
- Only affects unchecked items

**Technical Notes**:
```dart
class ReorderableItemList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);

    return ReorderableListView.builder(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(itemsProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          key: ValueKey(item.id),
          leading: ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle),
          ),
          title: Text(item.name),
          // ... rest of item UI
        );
      },
    );
  }
}
```

```python
@router.post("/lists/{list_id}/items/reorder")
async def reorder_items(
    list_id: UUID,
    item_order: List[UUID],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    # Update sort_index for each item
    for index, item_id in enumerate(item_order):
        db.query(Item).filter(
            Item.id == item_id,
            Item.list_id == list_id
        ).update({"sort_index": index})

    db.commit()

    # Broadcast reorder event
    await broadcast_list_update(list_id, {
        "type": "items_reordered",
        "order": [str(id) for id in item_order]
    })

    return {"success": True}
```

### Story 4.3: Chronological Sort

**Description**: Items sorted by when they were added.

**Acceptance Criteria**:
- Default sort mode for new lists
- Most recently added at top
- Option to reverse (oldest first)
- Respects created_at timestamp

### Story 4.4: Manage Checked Items

**Description**: Control visibility and clearing of checked items.

**Acceptance Criteria**:
- Toggle: "Show checked items" (default on)
- When hidden, show "X checked items" collapsed section
- Tap collapsed section to expand
- "Clear checked items" bulk action in list menu
- Confirmation dialog for bulk clear
- Undo snackbar after clear

**Technical Notes**:
```dart
class CheckedItemsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showChecked = ref.watch(showCheckedItemsProvider);
    final checkedItems = ref.watch(checkedItemsProvider);

    if (checkedItems.isEmpty) return SizedBox.shrink();

    if (!showChecked) {
      return ListTile(
        leading: Icon(Icons.check_circle_outline),
        title: Text('${checkedItems.length} checked items'),
        trailing: Icon(Icons.expand_more),
        onTap: () => ref.read(showCheckedItemsProvider.notifier).toggle(),
      );
    }

    return Column(
      children: [
        Divider(),
        ListTile(
          title: Text('Checked', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: TextButton(
            onPressed: () => _confirmClearChecked(context, ref),
            child: Text('Clear all'),
          ),
        ),
        ...checkedItems.map((item) => CheckedItemTile(item: item)),
      ],
    );
  }
}
```

---

## Epic 5: User Experience Enhancements

### Context for AI Session

```
EPIC: User Experience Enhancements
GOAL: Polish the app with quality-of-life features.

MVP FEATURES:
1. Dark Mode - Eye-friendly dark theme
2. Accessibility - Screen reader, high contrast
3. Screen Always On - Prevent timeout while shopping
4. Undo/Redo - Mistake recovery

FUTURE (not in MVP):
- Home Screen Widget
- Multi-Language (40+ languages)
```

### Story 5.1: Dark Mode

**Description**: Alternative dark color scheme.

**Acceptance Criteria**:
- Toggle in settings: Light, Dark, System
- Full theme support (all screens)
- Smooth transition animation
- Persist preference
- OLED-friendly true black option

**Technical Notes**:
```dart
// Theme configuration
final lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Colors.grey.shade50,
  cardColor: Colors.white,
  // ... more theme properties
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  // ... more theme properties
);

final oledDarkTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.black,
  cardColor: Color(0xFF0A0A0A),
);

// Theme provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'system';
    state = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

// In app.dart
MaterialApp(
  themeMode: ref.watch(themeModeProvider),
  theme: lightTheme,
  darkTheme: darkTheme,
)
```

### Story 5.2: Accessibility

**Description**: Full accessibility support.

**Acceptance Criteria**:
- Screen reader labels on all interactive elements
- Minimum touch target 48x48dp
- High contrast mode option
- Reduce motion option
- Focus indicators visible
- Semantic ordering of elements
- Sufficient color contrast ratios (WCAG AA)

**Technical Notes**:
```dart
// Semantic labels example
Semantics(
  label: 'Add item to shopping list',
  button: true,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: _addItem,
  ),
)

// Touch target sizing
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.check),
    onPressed: _toggleCheck,
  ),
)

// High contrast support
class HighContrastTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
    ),
    // High contrast borders and indicators
  );
}
```

### Story 5.3: Keep Screen On

**Description**: Prevent screen timeout while shopping.

**Acceptance Criteria**:
- Toggle in settings (default off)
- Can also enable per-list via list menu
- Show indicator when active (subtle icon in app bar)
- Respect device battery saver mode
- Auto-disable after 30 min inactivity
- Disable when app backgrounded

**Technical Notes**:
```dart
// Using wakelock package
class ScreenWakeService {
  bool _isEnabled = false;
  Timer? _inactivityTimer;

  Future<void> enable() async {
    if (await _shouldRespectBatterySaver()) return;

    await WakelockPlus.enable();
    _isEnabled = true;
    _resetInactivityTimer();
  }

  Future<void> disable() async {
    await WakelockPlus.disable();
    _isEnabled = false;
    _inactivityTimer?.cancel();
  }

  void onUserActivity() {
    if (_isEnabled) {
      _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 30), disable);
  }

  Future<bool> _shouldRespectBatterySaver() async {
    final batteryState = await Battery().batteryState;
    return batteryState == BatteryState.charging ? false :
           await Battery().batteryLevel < 20;
  }
}
```

### Story 5.4: Undo/Redo Support

**Description**: Recover from accidental actions.

**Acceptance Criteria**:
- Undo snackbar after: delete item, check item, clear checked
- "Undo" button visible for 5 seconds
- Multiple undo levels (last 10 actions)
- Works offline (undo local state)
- Sync undo actions when online

**Technical Notes**:
```dart
// Action history for undo
class UndoManager {
  final _history = Queue<UndoableAction>();
  static const maxHistory = 10;

  void record(UndoableAction action) {
    if (_history.length >= maxHistory) {
      _history.removeFirst();
    }
    _history.addLast(action);
  }

  Future<void> undo() async {
    if (_history.isEmpty) return;
    final action = _history.removeLast();
    await action.undo();
  }

  bool get canUndo => _history.isNotEmpty;
}

abstract class UndoableAction {
  Future<void> undo();
  String get description;
}

class DeleteItemAction implements UndoableAction {
  final Item deletedItem;
  final ItemsNotifier notifier;

  DeleteItemAction(this.deletedItem, this.notifier);

  @override
  Future<void> undo() async {
    await notifier.restoreItem(deletedItem);
  }

  @override
  String get description => 'Delete ${deletedItem.name}';
}

// Show undo snackbar
void showUndoSnackbar(BuildContext context, UndoableAction action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(action.description),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => ref.read(undoManagerProvider).undo(),
      ),
    ),
  );
}
```

---

## Epic 8: Cross-Platform & Sync

### Context for AI Session

```
EPIC: Cross-Platform & Sync
GOAL: Seamless experience across all devices.

PLATFORMS:
- iOS (iPhone, iPad)
- Android (Phone, Tablet)
- Web (PWA)
- (Future: watchOS, Wear OS)

SYNC STRATEGY:
1. Offline-first with local SQLite
2. Background sync when online
3. Real-time WebSocket when app active
4. Conflict resolution via vector clocks
5. Selective sync (active lists only)

AUTH:
- Email/password
- Social login (Google, Apple)
- Optional anonymous mode (device-bound)
```

### Story 8.1: User Registration

**Description**: Users can create accounts.

**Acceptance Criteria**:
- Email + password registration
- Password requirements: 8+ chars, mixed case, number
- Email verification required
- Welcome email with tips
- Import local data after signup

### Story 8.2: User Login

**Description**: Users can sign into their accounts.

**Acceptance Criteria**:
- Email + password login
- "Remember me" option
- Forgot password flow
- Social login: Google, Apple Sign In
- Biometric unlock (after first login)

### Story 8.3: Anonymous Mode

**Description**: Use app without account.

**Acceptance Criteria**:
- Skip signup option
- Data stored locally only
- Sharing disabled (requires account)
- Prompt to create account for sync
- Easy upgrade path (merge local → account)

### Story 8.4: Offline Support

**Description**: Full functionality without internet.

**Acceptance Criteria**:
- All CRUD operations work offline
- Data stored in local SQLite
- Queue changes for sync
- Visual indicator: "Offline mode"
- Sync automatically on reconnect

**Technical Notes**:
```dart
// Sync queue implementation
class SyncQueue {
  final _box = Hive.box<SyncAction>('sync_queue');

  Future<void> enqueue(SyncActionType type, dynamic payload) async {
    final action = SyncAction(
      id: uuid.v4(),
      type: type,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      attempts: 0,
    );
    await _box.put(action.id, action);
  }

  Future<void> processQueue() async {
    final actions = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final action in actions) {
      try {
        await _executeAction(action);
        await _box.delete(action.id);
      } catch (e) {
        action.attempts++;
        if (action.attempts >= 5) {
          // Move to dead letter queue
          await _deadLetterQueue.add(action);
          await _box.delete(action.id);
        } else {
          await _box.put(action.id, action);
        }
      }
    }
  }
}
```

### Story 8.5: Conflict Resolution

**Description**: Handle sync conflicts gracefully.

**Acceptance Criteria**:
- Detect conflicts via updated_at comparison
- Non-conflicting fields: merge automatically
- Conflicting fields: last-write-wins
- Edge case: both users edit same item name → keep most recent
- Log conflicts for debugging

---

## API Specification

### Authentication Endpoints

```yaml
POST /api/v1/auth/register:
  body:
    email: string (required)
    password: string (required, 8+ chars)
    name: string (optional)
  response: { user: User, access_token: string, refresh_token: string }

POST /api/v1/auth/login:
  body:
    email: string
    password: string
  response: { user: User, access_token: string, refresh_token: string }

POST /api/v1/auth/refresh:
  body:
    refresh_token: string
  response: { access_token: string }

POST /api/v1/auth/logout:
  headers:
    Authorization: Bearer {token}
  response: { success: true }
```

### List Endpoints

```yaml
GET /api/v1/lists:
  headers:
    Authorization: Bearer {token}
  params:
    include_archived: boolean (default: false)
  response: List[ListWithMeta]

POST /api/v1/lists:
  body:
    name: string (required)
    color: string (optional, hex)
    icon: string (optional)
  response: List

GET /api/v1/lists/{list_id}:
  response: ListWithItems

PATCH /api/v1/lists/{list_id}:
  body:
    name: string (optional)
    color: string (optional)
    icon: string (optional)
    is_archived: boolean (optional)
  response: List

DELETE /api/v1/lists/{list_id}:
  response: { success: true }

POST /api/v1/lists/{list_id}/duplicate:
  body:
    name: string (optional, default: "{original} (Copy)")
  response: List
```

### Item Endpoints

```yaml
GET /api/v1/lists/{list_id}/items:
  params:
    include_checked: boolean (default: true)
  response: List[Item]

POST /api/v1/lists/{list_id}/items:
  body:
    name: string (required)
    quantity: number (optional, default: 1)
    unit: string (optional)
    note: string (optional)
  response: Item

POST /api/v1/lists/{list_id}/items/batch:
  body:
    items: List[ItemCreate]
  response: List[Item]

PATCH /api/v1/items/{item_id}:
  body: ItemUpdate (all fields optional)
  response: Item

PATCH /api/v1/items/{item_id}/check:
  body:
    checked: boolean
  response: Item

DELETE /api/v1/items/{item_id}:
  response: { success: true }

DELETE /api/v1/lists/{list_id}/items/checked:
  response: { deleted_count: number }

POST /api/v1/lists/{list_id}/items/reorder:
  body:
    item_order: List[UUID]
  response: { success: true }
### Sharing Endpoints

```yaml
GET /api/v1/lists/{list_id}/members:
  response: List[ListMember]

POST /api/v1/lists/{list_id}/invite:
  body:
    email: string
    role: "editor" | "viewer"
  response: { status: "invited" | "added" }

POST /api/v1/lists/{list_id}/link:
  body:
    enabled: boolean
    role: "editor" | "viewer"
  response: { link: string | null }

PATCH /api/v1/lists/{list_id}/members/{user_id}:
  body:
    role: "editor" | "viewer"
  response: ListMember

DELETE /api/v1/lists/{list_id}/members/{user_id}:
  response: { success: true }

POST /api/v1/join/{token}:
  response: List
```

### WebSocket Protocol

```yaml
# Connect
WSS /ws/lists/{list_id}?token={jwt}

# Server → Client messages:
- { type: "item_added", item: Item }
- { type: "item_updated", item: Item }
- { type: "item_deleted", item_id: UUID }
- { type: "item_checked", item_id: UUID, checked: boolean, by: User }
- { type: "items_reordered", order: List[UUID] }
- { type: "user_joined", user: UserPreview }
- { type: "user_left", user_id: UUID }
- { type: "user_typing", user_id: UUID, user_name: string }

# Client → Server messages:
- { type: "typing" }
- { type: "ping" }
```

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-3)

**Backend:**
- [ ] FastAPI project setup with proper structure
- [ ] PostgreSQL models and migrations (users, lists, items, list_members)
- [ ] JWT authentication system
- [ ] User registration/login endpoints
- [ ] Social auth (Google, Apple)
- [ ] List CRUD endpoints
- [ ] Item CRUD endpoints

**Frontend:**
- [ ] Flutter project setup with clean architecture
- [ ] Navigation and routing (GoRouter)
- [ ] Authentication screens (login, register, forgot password)
- [ ] List home screen with grid/list view
- [ ] Create/edit list modal
- [ ] Local SQLite storage setup
- [ ] Basic theming (light mode)

**Deliverable:** Single-user, online-only list management with auth

### Phase 2: Collaboration (Weeks 4-6)

**Backend:**
- [ ] WebSocket infrastructure and connection manager
- [ ] Real-time list sync broadcasting
- [ ] Sharing and invitation system
- [ ] Link sharing with tokens
- [ ] Push notification integration (Firebase)
- [ ] Member role management

**Frontend:**
- [ ] Item list screen with quick add
- [ ] Item detail/edit form
- [ ] Check/uncheck with animations
- [ ] Real-time updates via WebSocket
- [ ] Share list UI and member management
- [ ] Typing indicators
- [ ] Push notification handling

**Deliverable:** Multi-user collaboration with real-time sync

### Phase 3: Polish & Offline (Weeks 7-9)

**Backend:**
- [ ] Conflict resolution logic
- [ ] Batch sync endpoint
- [ ] Performance optimization
- [ ] Rate limiting
- [ ] Redis caching for active lists

**Frontend:**
- [ ] Offline queue with Hive
- [ ] Sync status indicators
- [ ] Sorting options (alphabetical, custom, chronological)
- [ ] Drag-and-drop reordering
- [ ] Dark mode and OLED theme
- [ ] Accessibility pass (screen readers, touch targets)
- [ ] Keep screen on feature
- [ ] Undo/redo system
- [ ] Onboarding flow
- [ ] Settings screen

**Deliverable:** Production-ready MVP

### MVP Feature Checklist

| Feature | Backend | Frontend | Status |
|---------|---------|----------|--------|
| User registration/login | ✓ | ✓ | |
| Social auth (Google/Apple) | ✓ | ✓ | |
| Anonymous mode | ✓ | ✓ | |
| Create/edit/delete lists | ✓ | ✓ | |
| List colors and icons | ✓ | ✓ | |
| Archive/restore lists | ✓ | ✓ | |
| Duplicate lists | ✓ | ✓ | |
| Add/edit/delete items | ✓ | ✓ | |
| Item quantity and unit | ✓ | ✓ | |
| Item notes | ✓ | ✓ | |
| Check/uncheck items | ✓ | ✓ | |
| Batch add items | ✓ | ✓ | |
| Share via email | ✓ | ✓ | |
| Share via link | ✓ | ✓ | |
| Member management | ✓ | ✓ | |
| Real-time sync | ✓ | ✓ | |
| Push notifications | ✓ | ✓ | |
| Typing indicators | ✓ | ✓ | |
| Alphabetical sort | - | ✓ | |
| Custom sort (drag) | ✓ | ✓ | |
| Chronological sort | - | ✓ | |
| Hide/show checked items | - | ✓ | |
| Clear checked items | ✓ | ✓ | |
| Offline support | ✓ | ✓ | |
| Conflict resolution | ✓ | ✓ | |
| Dark mode | - | ✓ | |
| Accessibility | - | ✓ | |
| Keep screen on | - | ✓ | |
| Undo actions | - | ✓ | |

---

## Future Enhancements

The following features are planned for post-MVP releases:

### Smart Features (v1.1)

**Voice Input**
- Microphone button for hands-free item entry
- Speech-to-text with quantity parsing ("two pounds of chicken")
- Works offline using device speech recognition

**Smart Suggestions**
- Personalized product recommendations based on shopping history
- Popular items from product catalog
- Context-aware suggestions (suggest milk when eggs added)

**Shopping History**
- Track items purchased for future suggestions
- Frequency and recency tracking
- Price history for budget insights

**Auto-Categorization**
- Automatically assign categories to items
- Learn from user corrections
- Fuzzy matching against product catalog

**Product Catalog**
- Browsable database with images
- Dietary filters (Keto, Vegan, Gluten-Free)
- Localized product names

### Budget & Pricing (v1.2)

**Item Prices**
- Optional price field per item
- Price memory (remember last price)
- Currency localization

**Cost Calculator**
- Estimated total before shopping
- Running total as items checked off
- Price × quantity automatic calculation

**Budget Tracking**
- Set budget per list
- Visual progress indicator
- Overspend warnings

### Categories (v1.3)

**Category System**
- Default categories (Produce, Dairy, Meat, etc.)
- Items grouped under category headers
- Collapsible category sections

**Custom Categories**
- Create user-defined categories
- Custom icons and colors
- Reorder to match store layout

**Category Sorting**
- Sort items by category
- Category order customization per store

### Platform Expansion (v2.0)

**Web App (PWA)**
- Flutter web build
- Progressive Web App for installability
- Responsive design for desktop
- Keyboard shortcuts

**Multi-Language**
- 40+ language support
- RTL support (Arabic, Hebrew)
- Localized product catalog
- Number/currency/date formatting

**Home Screen Widgets**
- iOS widgets showing current list
- Android widgets with multiple sizes
- Quick add from widget

**Wearables**
- watchOS companion app
- Wear OS companion app
- Voice add from watch

---

## Appendix: Environment Variables

```bash
# Backend (.env)
DATABASE_URL=postgresql://user:pass@localhost:5432/listonit
REDIS_URL=redis://localhost:6379
JWT_SECRET_KEY=your-super-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=notifications@listonit.app
SMTP_PASSWORD=xxx
FIREBASE_CREDENTIALS=path/to/firebase.json

# Frontend (config.dart)
const String apiBaseUrl = 'https://api.listonit.app';
const String wsBaseUrl = 'wss://api.listonit.app';
```

---

*Document Version: 1.0*
*Last Updated: January 2026*
*For use by AI development sessions to build Listonit*

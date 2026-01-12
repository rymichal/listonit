# Epic 3: Sharing & Collaboration

## Context

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

## Stories

- [Story 3.1: Share List via Email](stories/story-1-share-list-via-email.md)
- [Story 3.2: Share List via Link](stories/story-2-share-list-via-link.md)
- [Story 3.3: Manage List Members](stories/story-3-manage-list-members.md)
- [Story 3.4: Real-Time Sync](stories/story-4-real-time-sync.md)
- [Story 3.5: Push Notifications](stories/story-5-push-notifications.md)
- [Story 3.6: Typing Indicators](stories/story-6-typing-indicators.md)

# Epic 6: Cross-Platform & Sync

## Context

EPIC: Cross-Platform & Sync
GOAL: Seamless experience across all devices.

PLATFORMS:
- iOS (iPhone, iPad)
- Android (Phone, Tablet)

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

## Stories

- [Story 6.1: User Registration](stories/story-1-user-registration.md)
- [Story 6.2: User Login](stories/story-2-user-login.md)
- [Story 6.3: Anonymous Mode](stories/story-3-anonymous-mode.md)
- [Story 6.4: Offline Support](stories/story-4-offline-support.md)
- [Story 6.5: Conflict Resolution](stories/story-5-conflict-resolution.md)

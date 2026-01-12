# Epic 1: Core List Management

## Context

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

## Technical Requirements
- Lists are stored both locally (SQLite) and remotely (PostgreSQL)
- Offline list creation must sync when connectivity returns
- List updates trigger real-time notifications to shared members
- Support optimistic UI updates with rollback on failure

## State Management
- Flutter: Use Riverpod for list state

## API
- RESTful CRUD at /api/v1/lists

## Stories

- [Story 1.1: Create New List](stories/story-1-create-new-list.md)
- [Story 1.2: View All Lists](stories/story-2-view-all-lists.md)
- [Story 1.3: Edit List Properties](stories/story-3-edit-list-properties.md)
- [Story 1.4: Delete List](stories/story-4-delete-list.md)
- [Story 1.5: Duplicate List](stories/story-5-duplicate-list.md)
- [Story 1.6: Archive/Restore Lists](stories/story-6-archive-restore-lists.md)

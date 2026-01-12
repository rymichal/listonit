# Epic 2: Item Management

## Context

EPIC: Item Management
GOAL: Implement item CRUD with essential metadata support.

Each item has:
- Name (required)
- Quantity (numeric, default 1)
- Unit (dropdown: pcs, kg, lb, oz, L, gal, dozen, pack, etc.)
- Note (free text for brand, size, reminders)
- Checked status (with timestamp and who checked)
- Sort index (for custom ordering)

## Interactions
- Quick add: Type name, press enter (minimal friction)
- Inline edit: Tap any field to modify
- Check off: Tap or swipe
- Bulk actions: Multi-select for delete/check

## Offline Requirements
- All item operations work offline
- Conflict resolution: Last-write-wins with merge for non-conflicting fields

## Stories

- [Story 2.1: Add Item (Quick Mode)](stories/story-1-add-item-quick-mode.md)
- [Story 2.2: Add Item with Details](stories/story-2-add-item-with-details.md)
- [Story 2.3: Edit Item Inline](stories/story-3-edit-item-inline.md)
- [Story 2.4: Check/Uncheck Items](stories/story-4-check-uncheck-items.md)
- [Story 2.5: Delete Items](stories/story-5-delete-items.md)
- [Story 2.6: Bulk Item Actions](stories/story-6-bulk-item-actions.md)

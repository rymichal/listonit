# Claude Code System Prompt for Listonit

You are an AI assistant developing **Listonit**, a collaborative shopping list application.

## Key Resources

- **Epic & Story Navigation**: See `.context/EPICS_AND_FEATURES_GUIDE.md`
- **All Stories**: `.context/epics/`
- **Full Project Plan**: `.context/listonit-project-plan.md`

## Tech Stack

- **Frontend**: Flutter (Riverpod for state management, Dart)
- **Backend**: FastAPI (Python 3.11+, SQLAlchemy ORM)
- **Database**: PostgreSQL
- **Real-time**: WebSockets, Redis pub/sub
- **Authentication**: JWT with refresh tokens
- **Local Storage**: SQLite (mobile), SharedPreferences
- **Mobile Platforms**: iOS & Android

## Story Reference Notation

When the user says "implement 1.1" or "feature 1.1", they mean:
- **Epic 1, Story 1** (Core List Management - Create New List)
- Format: `{epic_number}.{story_number}`

Examples:
- `2.3` = Epic 2, Story 3 (Edit Item Inline)
- `3.5` = Epic 3, Story 5 (Push Notifications)
- `6.4` = Epic 6, Story 4 (Offline Support)

Always locate the story at: `.context/epics/epic-{epic#}-{name}/stories/story-{story#}-{description}.md`

## Project Structure

```
listonit/
├── backend/
│   ├── main.py
│   ├── config.py
│   ├── api/
│   │   ├── v1/
│   │   │   ├── endpoints/
│   │   │   │   ├── auth.py
│   │   │   │   ├── lists.py
│   │   │   │   ├── items.py
│   │   │   │   └── sharing.py
│   │   │   └── router.py
│   │   └── deps.py
│   ├── models/           # SQLAlchemy models
│   ├── schemas/          # Pydantic schemas
│   ├── services/         # Business logic
│   └── repositories/     # Data access layer
│
└── client/listonit/      # Flutter app
    └── lib/
        ├── main.dart
        ├── app/
        │   ├── app.dart
        │   ├── routes.dart
        │   └── theme.dart
        ├── core/
        │   ├── constants/
        │   ├── errors/
        │   ├── network/
        │   ├── storage/
        │   └── utils/
        ├── features/
        │   ├── auth/
        │   ├── lists/
        │   ├── items/
        │   ├── sharing/
        │   └── settings/
        └── shared/
            ├── widgets/
            └── providers/
```

## When Implementing a Story

1. **Locate the story file**
   - Navigate to `.context/epics/epic-{#}-{name}/stories/story-{#}-{description}.md`
   - Or use `.context/epics/INDEX.md` to find it

2. **Read and understand acceptance criteria**
   - This defines what "done" means
   - All items should be checked off before marking story complete

3. **Check dependencies**
   - Review "Dependencies" section in story file
   - Ensure prerequisite stories are completed first
   - Identify which stories can run in parallel

4. **Use provided code templates**
   - Copy code samples as starting points
   - Adapt to actual project structure and conventions
   - Don't treat templates as exact implementations

5. **Follow existing patterns**
   - Look at similar stories for patterns
   - Maintain consistency with rest of codebase
   - Use project conventions for naming, structure, error handling

6. **Test against acceptance criteria**
   - Verify each criterion is met
   - Consider edge cases
   - Ensure error handling is in place

## Backend Implementation Guidelines

### FastAPI Endpoints
- Location: `backend/api/v1/endpoints/`
- Use dependency injection for auth and database
- Include proper error handling (HTTPException)
- Add background tasks for async work
- Document expected inputs/outputs
- Implement proper validation with Pydantic schemas

### Database Models
- Location: `backend/models/`
- Use SQLAlchemy ORM
- Include timestamps (created_at, updated_at)
- Add indexes for common queries
- Implement soft deletes where appropriate
- Use UUIDs for primary keys

### Services & Business Logic
- Location: `backend/services/`
- Keep business logic separate from endpoints
- Handle transactions properly
- Implement conflict resolution
- Support offline sync patterns

## Frontend Implementation Guidelines

### State Management
- Use Riverpod with StateNotifier
- Organize providers by feature
- Separate data, domain, and presentation layers
- Handle loading, error, and success states
- Implement optimistic updates where appropriate

### UI Widgets
- Location: `lib/features/{feature}/presentation/`
- Use ConsumerWidget for Riverpod integration
- Implement proper error handling and loading states
- Follow Material Design guidelines
- Support both light and dark themes
- Ensure accessibility (semantic labels, touch targets)

### Local Storage
- Use SQLite for primary data
- Use SharedPreferences for simple settings
- Implement sync queue for offline changes
- Handle conflict resolution

## Important Conventions

### File Naming
- Epics: `epic-{number}-{kebab-case-name}/`
- Stories: `story-{number}-{kebab-case-description}.md`
- Story numbers reflect order within epic (not global)

### Acceptance Criteria
- Written from user/product perspective
- Specific and measurable
- Include both happy path and edge cases
- Use `[ ]` checkbox format for tracking progress

### Code Comments
- Explain "why", not "what"
- Reference story files when implementing complex logic
- Document edge cases and assumptions
- Include examples in docstrings

### Commits
- Reference story number: "feat(epic-1): 1.1 - Create new list"
- Keep commits focused on single stories or sub-tasks
- Update story file if implementation changes approach

## Quick Links

- **Start Here**: `.context/epics/INDEX.md`
- **Navigation Guide**: `.context/EPICS_AND_FEATURES_GUIDE.md`
- **Epic 1 (Core Lists)**: `.context/epics/epic-1-core-list-management/README.md`
- **Epic 2 (Item Mgmt)**: `.context/epics/epic-2-item-management/README.md`
- **Epic 3 (Collab)**: `.context/epics/epic-3-sharing-collaboration/README.md`
- **Epic 4 (Sorting)**: `.context/epics/epic-4-organization-sorting/README.md`
- **Epic 5 (UX)**: `.context/epics/epic-5-user-experience/README.md`
- **Epic 6 (Sync)**: `.context/epics/epic-6-cross-platform-sync/README.md`

## Tips for Implementation

### Before Starting
- Ask for clarification about project structure if unsure
- Request existing code examples if creating similar features
- Confirm database schema and API contracts

### During Implementation
- Reference similar stories for patterns
- Test against acceptance criteria frequently
- Ask for feedback on approach if uncertain
- Document assumptions and decisions

### After Implementation
- Verify all acceptance criteria are met
- Ensure error handling is comprehensive
- Check that code follows project conventions
- Update related documentation if needed

---

**Total Project Scope:**
- **31 Stories** across 6 Epics
- **126 Story Points** of estimated effort
- **3 Implementation Phases** (Foundation → Collaboration → Polish & Offline)

**Current Phase**: Phase 1 - Foundation (Epics 1, 6.1-6.2)

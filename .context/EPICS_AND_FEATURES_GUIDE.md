# Listonit Epics & Features Guide for AI Agents

This guide explains how to navigate and understand the Listonit project's epic and story structure located in `.context/epics/`.

## Directory Structure Overview

```
.context/
├── epics/
│   ├── INDEX.md                              # Master index (START HERE)
│   ├── epic-1-core-list-management/
│   │   ├── README.md                         # Epic context and story links
│   │   └── stories/
│   │       ├── story-1-create-new-list.md
│   │       ├── story-2-view-all-lists.md
│   │       └── ... (6 stories total)
│   ├── epic-2-item-management/
│   │   ├── README.md
│   │   └── stories/ (6 stories)
│   ├── epic-3-sharing-collaboration/
│   │   ├── README.md
│   │   └── stories/ (6 stories)
│   ├── epic-4-organization-sorting/
│   │   ├── README.md
│   │   └── stories/ (4 stories)
│   ├── epic-5-user-experience/
│   │   ├── README.md
│   │   └── stories/ (4 stories)
│   └── epic-6-cross-platform-sync/
│       ├── README.md
│       └── stories/ (5 stories)
└── EPICS_AND_FEATURES_GUIDE.md              # This file
```

## How to Use This Structure

### 1. Start with the Index
Begin by reading [INDEX.md](epics/INDEX.md) to understand:
- All 6 epics at a glance
- Total story and effort counts
- Implementation phases
- Quick navigation links

### 2. Read Epic Context
Each epic folder contains a `README.md` that provides:
- **Context**: Business goals and technical requirements
- **Key Concepts**: Important domain knowledge
- **Links to Stories**: Direct navigation to all stories in that epic

### 3. Understand Individual Stories
Each story file (e.g., `story-1-create-new-list.md`) contains:

```markdown
# Story Title

## Description
User-facing description of what the story accomplishes.

## Acceptance Criteria
Checklist of requirements that define "done":
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Technical Implementation
Code samples for:
### FastAPI Endpoint(s)
- Python backend implementation
- Database queries
- Error handling

### Flutter Implementation
- Dart/Flutter UI code
- State management (Riverpod)
- Local storage integration

## Dependencies
- **Blocking Stories**: Must complete before this story
- **Related Stories**: Work well together but not strictly blocking
- **Infrastructure**: Required setup (auth, database, etc.)

## Estimated Effort
Story points (using standard Fibonacci: 1, 2, 3, 5, 8, 13)
```

## Key Information to Extract

### When Starting a Story

1. **Read the Acceptance Criteria** - This defines what "done" means
2. **Check Dependencies** - Understand what must be done first
3. **Review Technical Details** - Use provided code samples as templates
4. **Estimate Effort** - Use the provided story points for planning

### When Making Changes

1. **Find the Relevant Story** - Use directory structure to locate the right file
2. **Update Acceptance Criteria** - Check off completed items
3. **Modify Technical Details** - Update code samples if implementation changes
4. **Update Dependencies** - Adjust if new dependencies are discovered
5. **Note Changes** - Add comments about what was changed and why

### When Researching Features

1. **Search by Feature Name** - Find relevant stories
2. **Check Dependencies** - Understand the dependency chain
3. **Review Related Epics** - Some features span multiple epics
4. **Look for Code Samples** - Use provided implementations as reference

## Epic Summary

| Epic | Focus | Stories | Points | Phase |
|------|-------|---------|--------|-------|
| [Epic 1](epics/epic-1-core-list-management/README.md) | Core list CRUD | 6 | 22 | Phase 1 |
| [Epic 2](epics/epic-2-item-management/README.md) | Item management | 6 | 23 | Phase 2 |
| [Epic 3](epics/epic-3-sharing-collaboration/README.md) | Real-time collaboration | 6 | 28 | Phase 2 |
| [Epic 4](epics/epic-4-organization-sorting/README.md) | Sorting & organization | 4 | 10 | Phase 3 |
| [Epic 5](epics/epic-5-user-experience/README.md) | UX polish | 4 | 15 | Phase 3 |
| [Epic 6](epics/epic-6-cross-platform-sync/README.md) | Auth & sync | 5 | 28 | Phase 1,3 |

## Common Workflows

### Finding Related Features
1. Start at INDEX.md
2. Identify which epics contain related work
3. Navigate to each epic's README
4. Cross-reference stories and their dependencies

### Tracking Implementation Progress
1. Open the relevant story file
2. Check off acceptance criteria as they're completed
3. Update technical implementation with actual code
4. Note any deviations from original plan
5. Update dependencies if new blockers discovered

### Planning a Release/Sprint
1. Review the 3 implementation phases in INDEX.md
2. Select stories from the current phase
3. Check dependencies to ensure all blockers are clear
4. Sum story points for capacity planning
5. Track progress in acceptance criteria

### Adding New Features (Post-MVP)
1. Create new story file following naming convention
2. Link from relevant epic's README
3. Add to INDEX.md if creating new epic
4. Follow the same template structure

## Important Conventions

### File Naming
- Epics: `epic-{number}-{kebab-case-name}/`
- Stories: `story-{number}-{kebab-case-description}.md`
- Story numbers reflect order within epic (not global)

### Code Samples
- **Always include**: FastAPI endpoints and Flutter widgets
- **Format**: Use markdown code blocks with language specified
- **Purpose**: Templates for implementation, not complete solutions
- **Update**: When implementation details change significantly

### Dependencies Section
- Lists stories that must complete first
- Includes infrastructure requirements
- Notes if a story can work in parallel with others
- Essential for sprint planning

### Acceptance Criteria
- Written from user/product perspective
- Specific and measurable
- Include both happy path and edge cases
- Marked with `[ ]` for easy progress tracking

## Tips for AI Agents

### When Implementing
1. Copy code samples as starting points
2. Adapt to actual project setup and naming conventions
3. Follow existing patterns from other stories in same epic
4. Test against acceptance criteria, not just implementation

### When Refactoring
1. Update relevant story files if behavior changes
2. Check all dependent stories - ensure changes don't break them
3. Update code samples in related stories if patterns change
4. Document why the change was necessary

### When Debugging
1. Review acceptance criteria - is this actually required?
2. Check dependencies - is a prerequisite story complete?
3. Look at similar stories - how do they handle this?
4. Review code samples - are there edge cases?

### When Estimating
1. Use provided story points as baseline
2. Factor in actual project setup complexity
3. Consider team familiarity with tech stack
4. Adjust if design changes significantly from templates

## Navigation Quick Links

- **Start Here**: [INDEX.md](epics/INDEX.md)
- **Epic 1 (Lists)**: [README.md](epics/epic-1-core-list-management/README.md)
- **Epic 2 (Items)**: [README.md](epics/epic-2-item-management/README.md)
- **Epic 3 (Collab)**: [README.md](epics/epic-3-sharing-collaboration/README.md)
- **Epic 4 (Sorting)**: [README.md](epics/epic-4-organization-sorting/README.md)
- **Epic 5 (UX)**: [README.md](epics/epic-5-user-experience/README.md)
- **Epic 6 (Sync)**: [README.md](epics/epic-6-cross-platform-sync/README.md)

## Questions?

If you're unsure about a story:
1. Check the acceptance criteria - what does "done" mean?
2. Review dependencies - what's the prerequisite work?
3. Look at the technical implementation - how has this been designed?
4. Check the epic README - what's the broader context?
5. Look at related stories - how do similar features work?

---

**Total Project Scope:**
- **31 Stories** across 6 Epics
- **126 Story Points** of estimated effort
- **3 Implementation Phases**
- Designed for agile iteration with clear phase gates

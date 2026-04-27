# AI-Assisted Development Workflow

## Tools Used

**Primary**: Claude Code (claude-sonnet-4-6) via the Claude Code CLI in a GitHub Codespace

**Secondary (for reference)**: Claude.ai web for initial architecture brainstorming

---

## How AI Was Used

### 1. Architecture Planning

I used Claude to think through the data model before writing a single line of code. Prompted it with the full problem statement and asked for a complete ERD-style breakdown:

> "Given this scheduling domain (professionals, managers, multi-type entries, RSVP, audit trail), design a normalized schema with the fewest tables needed."

Claude proposed the polymorphic `source_type/source_id` pattern for auto-linked entries — a clean solution I refined slightly (keeping it on `schedule_entries` rather than a separate junction table).

### 2. Rails Migrations & Models

Generated the migration scaffolding via `bin/rails generate migration`, then used Claude to fill in the full column definitions with correct types, defaults, and indexes. For models, I described the behavior I wanted (conflict detection, auto-notifications, audit trail) and Claude produced the full model code which I reviewed and adjusted.

**Validation I did manually:**
- Confirmed `for_date_range` overlap query logic against PostgreSQL docs
- Verified the `Auditable` concern's callback chain ordering
- Tested the polymorphic `has_many :schedule_entries, as: :source` association

### 3. API Controllers

Claude generated all 7 controllers from a brief spec:
> "Write a Rails API controller for schedule_entries. It should support CRUD, filtering by user_id/date range/entry_type, conflict checking, and cancellation. Managers can edit any managed professional's entries."

Generated output was correct in structure; I refined:
- The `authorize_user_access!` logic (added admin bypass)
- Pagination meta format to match Flutter client expectations
- Nested `entry_json` serialization (added `conflicts` and `rsvp_summary` in detailed mode)

### 4. Flutter App

Used Claude for the full Flutter scaffolding:
- Provider pattern architecture (4 providers: auth, schedule, task, notification)
- Responsive layout (NavigationRail on tablet, BottomNavigationBar on mobile)
- `table_calendar` integration with event markers
- RSVP UI with response buttons

**Generated directly (minimal manual changes):**
- `ApiService` HTTP layer
- All model classes (fromJson)
- Provider classes

**Manually refined:**
- Calendar entry color coding system
- Conflict warning UI in create form
- Tablet two-pane layout proportions

### 5. Debugging

When PostgreSQL migrations weren't applying columns correctly (an Aiven-specific transaction behavior), I described the symptom to Claude:
> "Migration shows 'up' in status but columns aren't created. Runner scripts work fine."

Claude correctly diagnosed: columns were missing and proposed using `add_column` via runner as a workaround, then marking migrations as applied.

---

## Prompting Approach

**Effective prompts included:**
- Full context upfront: domain, constraints, tech stack, existing code
- Concrete examples of desired input/output
- Explicit mention of edge cases: "what happens when a manager edits a professional's entry?"

**Avoided:**
- "Write code for X" without context → got generic code
- Incremental one-at-a-time requests → less coherent output

---

## What Was Generated vs. Manually Refined

| Component | Generated | Refined |
|-----------|-----------|---------|
| DB Schema | Structure + basic columns | Added indexes, defaults, polymorphic links |
| Models | Full code | Conflict logic tuning, notification text |
| Controllers | Full code | Permission edge cases, serialization depth |
| Flutter providers | Full code | Minor naming conventions |
| Flutter screens | Full code | Responsive breakpoints, color system |
| Architecture decisions | Options presented | Final choices + tradeoffs made by me |

---

## How I Validated Output

1. **Static analysis**: `flutter analyze` caught unused imports and type errors before runtime
2. **Rails routes**: `bin/rails routes --grep api` verified all endpoints were registered
3. **Live API testing**: `curl` tested auth, schedule entries, notifications, and conflict detection end-to-end against real Aiven PostgreSQL
4. **Seed data**: Created realistic demo data and verified counts + response shapes
5. **Migration status**: `bin/rails db:migrate:status` confirmed all migrations applied

---

## Engineering Judgment Exercised

- **Chose soft delete over hard delete** — preserves audit trail integrity
- **Synchronous notifications** over async jobs — right scope for this module; jobs would be premature optimization
- **Polymorphic source** over separate junction tables — extensible without schema changes when new source types (e.g., "contract", "casting call") are added
- **JWT over sessions** — Flutter mobile/web clients benefit from stateless auth; no CSRF complexity
- **Conflict detection on save** — stores `has_conflict` flag so list views don't need expensive re-computation; acceptable stale window since recomputed on every mutation

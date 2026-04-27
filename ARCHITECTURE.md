# Schedulr — Architecture & Design Note

## Overview

Schedulr is a multi-user scheduling and task coordination module built for professionals (models, actors, freelancers) and their managers/coordinators. The calendar is the single source of truth for day-to-day schedule coordination.

---

## System Architecture

```
┌─────────────────────┐     HTTPS/JSON      ┌──────────────────────────┐
│   Flutter Client     │ ◄──────────────────► │  Rails 8 API Server      │
│   (Web + Mobile)    │                      │  (api/v1 namespace)      │
└─────────────────────┘                      └──────────────┬───────────┘
                                                            │
                                                            ▼
                                               ┌──────────────────────┐
                                               │  PostgreSQL (Aiven)  │
                                               │  (Cloud-hosted)      │
                                               └──────────────────────┘
```

**Backend**: Ruby on Rails 8.1 (API-ready), serving JSON via `api/v1` namespace  
**Database**: PostgreSQL (Aiven cloud-hosted)  
**Auth**: Stateless JWT tokens (24h expiry, `HS256`)  
**Frontend**: Flutter (web + mobile, responsive)  
**CORS**: rack-cors allowing all origins (configure per environment in production)

---

## Data Model

### Core Models

#### `users`
| Column | Type | Notes |
|--------|------|-------|
| email | string | unique, required |
| name | string | required |
| role | string | `professional` / `manager` / `admin` |
| password_digest | string | bcrypt |
| phone, avatar_url, timezone | string | optional |
| active | boolean | soft disable |

#### `user_relationships`
Manager ↔ Professional many-to-many.  
`manager_id → users`, `professional_id → users`  
Unique constraint prevents duplicate relationships.

#### `schedule_entries` (central model)
| Column | Type | Notes |
|--------|------|-------|
| user_id | FK | the professional this entry belongs to |
| created_by_id | FK | who created it (manager or self) |
| updated_by_id | FK | audit trail |
| entry_type | string | 9 types (see below) |
| starts_at / ends_at | datetime | required, validated |
| status | string | `active` / `cancelled` |
| source_type / source_id | polymorphic | links to Project, Assignment, CalendarEvent |
| requires_rsvp | boolean | enables RSVP flow |
| has_conflict | boolean | computed on save |

**Entry types**: `available`, `not_available`, `busy`, `shoot_work_day`, `travel`, `personal_block`, `hold`, `tentative_booking`, `confirmed_booking`

#### `participations` (RSVP)
| Column | Type | Notes |
|--------|------|-------|
| user_id | FK | participant |
| schedule_entry_id | FK | the event |
| response | string | `pending` / `yes` / `no` / `maybe` |
| responded_at | datetime | set when response changes |

#### `tasks`
| Column | Type | Notes |
|--------|------|-------|
| user_id | FK | assignee |
| created_by_id | FK | creator (manager or self) |
| schedule_entry_id | FK | optional link to schedule entry |
| task_type | string | `submission_deadline`, `preparation_reminder`, `follow_up`, `checklist`, `general` |
| priority | string | `low` / `medium` / `high` / `urgent` |
| status | string | `pending` / `in_progress` / `completed` / `cancelled` |
| due_date | date | for calendar display |

#### `projects`, `assignments`, `calendar_events`
Source objects that auto-create linked `schedule_entries` via `after_create` callbacks. The polymorphic `source_type/source_id` on schedule entries creates the link back.

#### `audit_logs`
Every create/update/destroy on `ScheduleEntry`, `Task`, and `Participation` is recorded via the `Auditable` concern. Stores `previous` and `current` values as JSON.

#### `notifications`
Created automatically by model callbacks:
- Manager creates/changes entry → notifies professional
- RSVP response changes → notifies organizer
- Conflicts detected → warnings attached to entry

---

## API Structure

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/auth/me

GET    /api/v1/users              # managers see their professionals
GET    /api/v1/users/:id
GET    /api/v1/users/professionals
POST   /api/v1/users/assign_manager
DELETE /api/v1/users/remove_manager

GET    /api/v1/schedule_entries           # filterable: from, to, entry_type, user_id
POST   /api/v1/schedule_entries
GET    /api/v1/schedule_entries/:id
PUT    /api/v1/schedule_entries/:id
DELETE /api/v1/schedule_entries/:id       # soft cancels
POST   /api/v1/schedule_entries/:id/cancel
GET    /api/v1/schedule_entries/:id/conflicts
GET    /api/v1/schedule_entries/check_conflicts

GET    /api/v1/schedule_entries/:id/participations
POST   /api/v1/schedule_entries/:id/participations
PUT    /api/v1/schedule_entries/:sid/participations/:id

GET    /api/v1/tasks
POST   /api/v1/tasks
PUT    /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
POST   /api/v1/tasks/:id/complete

GET    /api/v1/notifications
POST   /api/v1/notifications/:id/mark_read
POST   /api/v1/notifications/mark_all_read

GET    /api/v1/audit_logs

GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/:id
PUT    /api/v1/projects/:id

GET    /api/v1/assignments
POST   /api/v1/assignments
PUT    /api/v1/assignments/:id
```

---

## Key Design Decisions

### 1. Conflict Detection
Conflicts are detected at the database level using an overlapping time range query:
```sql
WHERE starts_at < :ends_at AND ends_at > :starts_at
AND status = 'active' AND entry_type NOT IN ('available', 'not_available')
```
`has_conflict` is stored on the entry and recomputed on every save. The API also exposes `GET /check_conflicts` so the Flutter client can validate before saving.

### 2. Auto-linked Entries
Projects, Assignments, and CalendarEvents auto-create schedule entries via `after_create` callbacks. The `source_type / source_id` polymorphic association lets clients navigate from calendar entry → source object. If the source is cancelled or rescheduled, the linked entry is updated or cancelled automatically.

### 3. Permission Model
- **Professionals**: full CRUD on their own entries and tasks; read-only on what managers add
- **Managers**: can create/edit entries for any managed professional; see multi-user calendar
- **Admin**: unrestricted access
- All requests check ownership via `authorize_user_access!` in `BaseController`; managers are checked via `can_manage?(target_user)`

### 4. Audit Trail
The `Auditable` concern hooks into ActiveRecord callbacks and stores every state change in `audit_logs`. It uses `Current.user` (a `CurrentAttributes` store) set per-request in `BaseController#set_current_user`. This gives a complete "who changed what when" history.

### 5. Soft Delete
Schedule entries are never hard-deleted — they are `cancelled`. This preserves the audit trail and ensures the calendar history is never lost.

### 6. Notifications
Notifications are created synchronously in model callbacks (simple and reliable for this scale). Production would move these to background jobs (Sidekiq/GoodJob). The Flutter client polls notifications on app load.

---

## Assumptions

- One professional can have multiple managers (e.g., separate commercial and editorial managers)
- Conflicts only apply to "blocking" entry types; `available` / `not_available` entries never trigger conflicts
- Managers are assigned explicitly — no auto-discovery
- Timezone handling: all datetimes stored as UTC; client converts to local on display

---

## Tradeoffs

| Decision | Alternative | Reason |
|----------|------------|--------|
| JWT auth (stateless) | Session cookies | Better for Flutter mobile clients; no CSRF complexity |
| Synchronous notifications | Background jobs | Simpler for this scope; easily swapped out |
| Polymorphic source links | Separate junction tables | More flexible — new source types without schema changes |
| SQLite → PostgreSQL (Aiven) | Local PG | Immediate cloud availability; easy to share API URL |
| `has_conflict` stored flag | Compute on read | Faster list views; acceptable stale window (recomputed on save) |

---

## Setup Instructions

### Backend (Rails)

```bash
# Install dependencies
bundle install

# Database (Aiven PostgreSQL pre-configured)
bin/rails db:migrate
bin/rails db:seed

# Start server
bin/rails server -b 0.0.0.0 -p 3000
```

**Demo credentials:**
| Role | Email | Password |
|------|-------|----------|
| Manager | sarah.manager@talent.co | password123 |
| Professional | alex.johnson@model.com | password123 |
| Professional | maya.patel@talent.com | password123 |
| Professional | james.kim@actor.com | password123 |

### Flutter App

```bash
cd flutter_app
flutter pub get

# Run in browser
flutter run -d chrome

# Build web
flutter build web --release
```

Update `lib/utils/constants.dart` `baseUrl` to point to your Rails server.

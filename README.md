# Schedulr — Multi-User Scheduling & Task Coordination Module

A full-stack scheduling application built for professionals (models, actors, freelancers) and their managers. The calendar is the single source of truth for day-to-day schedule coordination.

## Live Demo

| | URL |
|---|---|
| **Flutter Web App** | https://schedulr-app-12bbf.web.app |
| **Rails API** | https://reelon-assignment.onrender.com/api/v1 |

### Demo Credentials

| Role | Email | Password |
|---|---|---|
| Manager | sarah.manager@talent.co | password123 |
| Professional | alex.johnson@model.com | password123 |
| Professional | maya.patel@model.com | password123 |
| Professional | james.wilson@model.com | password123 |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.1 (API mode) |
| Database | PostgreSQL (Aiven cloud) |
| Authentication | JWT (HS256, 24h expiry) |
| Frontend | Flutter 3 (Web + Mobile) |
| State Management | Provider |
| Hosting — API | Render.com |
| Hosting — App | Firebase Hosting |

---

## Features

- **9 Schedule Entry Types** — Available, Not Available, Busy, Shoot/Work Day, Travel, Personal Block, Hold, Tentative Booking, Confirmed Booking
- **Conflict Detection** — overlapping time range detection at the database level; flagged before save
- **Auto-Linked Entries** — Projects and Assignments automatically create linked schedule entries via model callbacks
- **Multi-User / Manager View** — managers can create and manage entries on behalf of their talent
- **RSVP / Participation** — invite participants; track Yes / No / Maybe responses
- **Task Management** — tasks with types, priorities, due dates, and optional calendar entry links
- **Notifications** — auto-created when a manager changes an entry or an RSVP is updated
- **Audit Trail** — every create/update/destroy on schedule entries, tasks, and participations is logged
- **Responsive UI** — NavigationRail on tablet (≥720px), BottomNavigationBar on mobile

---

## Project Structure

```
schedulr/
├── app/                        # Rails application
│   ├── controllers/api/v1/     # API controllers
│   ├── models/                 # ActiveRecord models
│   └── services/               # JsonWebToken service
├── config/
│   ├── routes.rb               # API routes (api/v1 namespace)
│   └── database.yml            # PostgreSQL config (via DATABASE_URL)
├── db/
│   ├── migrate/                # 17 migrations
│   ├── schema.rb
│   └── seeds.rb                # Demo data (4 users, entries, tasks)
├── flutter_app/                # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/             # Dart data models
│   │   ├── providers/          # Auth, Schedule, Task, Notification providers
│   │   ├── screens/            # Auth, Calendar, Tasks, Notifications, Profile
│   │   ├── services/           # ApiService (HTTP client)
│   │   └── utils/constants.dart
│   └── web/                    # Web-specific config
├── Dockerfile                  # Rails production Docker image
├── render.yaml                 # Render.com deployment config
└── CREDENTIALS.md              # Login credentials reference
```

---

## Local Setup

### Prerequisites

- Ruby 3.4.1
- Bundler
- Flutter 3.x
- PostgreSQL (or use the Aiven cloud URL below)

---

### 1. Backend — Rails API

```bash
# Clone the repo
git clone https://github.com/Nitin1692/reelon-assignment.git
cd reelon-assignment

# Install dependencies
bundle install

# Set environment variable (use Aiven cloud DB or your own PG instance)
export DATABASE_URL="postgres://avnadmin:<password>@pg-36499b79-nitinjain7201-41f1.d.aivencloud.com:13532/defaultdb?sslmode=require"

# Run migrations
bin/rails db:migrate

# Seed demo data
bin/rails db:seed

# Start the server
bin/rails server -b 0.0.0.0 -p 3000
```

API will be available at `http://localhost:3000/api/v1`

---

### 2. Frontend — Flutter App

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# Run on connected device
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# Build for web (production)
flutter build web --dart-define=API_BASE_URL=https://reelon-assignment.onrender.com/api/v1
```

---

## Environment Variables

### Rails (Backend)

| Variable | Description | Required |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `SECRET_KEY_BASE` | Rails secret key | Yes (production) |
| `RAILS_ENV` | `production` / `development` | Yes |
| `RAILS_LOG_TO_STDOUT` | Enable stdout logging | Recommended |
| `RAILS_SERVE_STATIC_FILES` | Serve static assets | Yes (production) |

### Flutter (Frontend)

| Variable | Description | Default |
|---|---|---|
| `API_BASE_URL` | Rails API base URL | `https://reelon-assignment.onrender.com/api/v1` |

Pass via `--dart-define=API_BASE_URL=...` at build or run time.

---

## API Reference

### Auth
```
POST   /api/v1/auth/register        # Sign up
POST   /api/v1/auth/login           # Sign in → returns JWT
GET    /api/v1/auth/me              # Current user (requires Bearer token)
```

### Schedule Entries
```
GET    /api/v1/schedule_entries              # List (filter: from, to, entry_type, user_id)
POST   /api/v1/schedule_entries              # Create
GET    /api/v1/schedule_entries/:id          # Show
PUT    /api/v1/schedule_entries/:id          # Update
DELETE /api/v1/schedule_entries/:id          # Soft cancel
POST   /api/v1/schedule_entries/:id/cancel   # Explicit cancel
GET    /api/v1/schedule_entries/check_conflicts  # Check before save
```

### Tasks
```
GET    /api/v1/tasks
POST   /api/v1/tasks
PUT    /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
POST   /api/v1/tasks/:id/complete
```

### Notifications
```
GET    /api/v1/notifications
POST   /api/v1/notifications/:id/mark_read
POST   /api/v1/notifications/mark_all_read
```

### Users (Manager access)
```
GET    /api/v1/users
GET    /api/v1/users/professionals
POST   /api/v1/users/assign_manager
```

All authenticated endpoints require:
```
Authorization: Bearer <jwt_token>
```

---

## Deployment

### Rails → Render.com

1. Push repo to GitHub
2. Go to [render.com](https://render.com) → **New → Blueprint**
3. Connect the repository — `render.yaml` is auto-detected
4. Add environment variable: `DATABASE_URL` = your PostgreSQL connection string
5. Deploy

### Flutter → Firebase Hosting

```bash
cd flutter_app

# Login to Firebase (one time)
firebase login

# Build web app
flutter build web --dart-define=API_BASE_URL=https://<your-render-url>/api/v1

# Deploy
firebase deploy
```

---

## Architecture Notes

- **Conflict detection** uses a SQL overlapping range query: `starts_at < ends_at AND ends_at > starts_at` — only on "blocking" entry types
- **Auto-linked entries** — `Project.after_create` and `Assignment.after_create` callbacks create `schedule_entries` with polymorphic `source_type/source_id` back-links
- **Audit trail** — `Auditable` concern hooks into `after_create/update/destroy` callbacks and stores diffs in `audit_logs` using `Current.user` (set per-request via `ActiveSupport::CurrentAttributes`)
- **Soft delete** — entries are never hard deleted; `status: cancelled` preserves history
- **Notifications** — created synchronously in model callbacks; production-ready to move to background jobs

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design document.

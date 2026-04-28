# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_28_040321) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "RefreshToken", id: :serial, force: :cascade do |t|
    t.datetime "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "expiresAt", precision: 3, null: false
    t.text "token", null: false
    t.integer "userId", null: false
    t.index ["token"], name: "RefreshToken_token_key", unique: true
  end

  create_table "Task", id: :serial, force: :cascade do |t|
    t.datetime "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.text "status", default: "pending", null: false
    t.text "title", null: false
    t.datetime "updatedAt", precision: 3, null: false
    t.integer "userId", null: false
  end

  create_table "User", id: :serial, force: :cascade do |t|
    t.datetime "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "email", null: false
    t.text "password", null: false
    t.index ["email"], name: "User_email_key", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.string "assignment_type", default: "assignment"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "location"
    t.text "notes"
    t.integer "project_id"
    t.datetime "scheduled_at"
    t.string "status", default: "pending"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "changes_data"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "calendar_events", force: :cascade do |t|
    t.boolean "all_day", default: false
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.text "description"
    t.datetime "ends_at"
    t.string "event_type", default: "general"
    t.string "location"
    t.datetime "starts_at"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type"
    t.boolean "read"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.datetime "responded_at"
    t.string "response"
    t.integer "schedule_entry_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.text "description"
    t.datetime "ends_at"
    t.datetime "starts_at"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "schedule_entries", force: :cascade do |t|
    t.boolean "all_day", default: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "ends_at"
    t.string "entry_type"
    t.boolean "has_conflict", default: false
    t.string "location"
    t.text "notes"
    t.boolean "requires_rsvp", default: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "starts_at"
    t.string "status", default: "active"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.date "due_date"
    t.time "due_time"
    t.string "priority", default: "medium"
    t.bigint "schedule_entry_id"
    t.string "status", default: "pending"
    t.string "task_type", default: "general"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
  end

  create_table "user_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "manager_id"
    t.integer "professional_id"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "phone"
    t.string "role"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "RefreshToken", "User", column: "userId", name: "RefreshToken_userId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Task", "User", column: "userId", name: "Task_userId_fkey", on_update: :cascade, on_delete: :cascade
end

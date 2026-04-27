puts "Seeding database..."

# Clear existing data
AuditLog.delete_all
Notification.delete_all
Participation.delete_all
Task.delete_all
ScheduleEntry.delete_all
Assignment.delete_all
Project.delete_all
UserRelationship.delete_all
User.delete_all

# Users
manager = User.create!(
  email: "sarah.manager@talent.co",
  name: "Sarah Chen",
  role: "manager",
  password: "password123",
  phone: "+1-555-0100",
  timezone: "America/New_York"
)

pro1 = User.create!(
  email: "alex.johnson@model.com",
  name: "Alex Johnson",
  role: "professional",
  password: "password123",
  phone: "+1-555-0101",
  timezone: "America/New_York"
)

pro2 = User.create!(
  email: "maya.patel@talent.com",
  name: "Maya Patel",
  role: "professional",
  password: "password123",
  phone: "+1-555-0102",
  timezone: "America/Los_Angeles"
)

pro3 = User.create!(
  email: "james.kim@actor.com",
  name: "James Kim",
  role: "professional",
  password: "password123",
  phone: "+1-555-0103",
  timezone: "America/Chicago"
)

# Manager relationships
UserRelationship.create!(manager: manager, professional: pro1)
UserRelationship.create!(manager: manager, professional: pro2)
UserRelationship.create!(manager: manager, professional: pro3)

now = Time.current

# ---- Projects ----
project1 = Project.new(
  title: "Summer Campaign - Vogue",
  description: "High fashion editorial for Vogue Summer Issue",
  starts_at: now + 7.days,
  ends_at: now + 9.days,
  status: "active",
  category: "editorial",
  created_by: manager
)
project1.save!(validate: false) # skip auto-linked schedule for seeding clarity

project2 = Project.new(
  title: "Nike Sportswear Campaign",
  description: "Athletic brand campaign for Fall collection",
  starts_at: now + 14.days,
  ends_at: now + 16.days,
  status: "active",
  category: "commercial",
  created_by: manager
)
project2.save!(validate: false)

# ---- Schedule Entries for Alex ----
# Suppress audit/notify callbacks during seeding by setting Current.user
Current.user = manager

ScheduleEntry.create!(
  user: pro1,
  created_by: manager,
  entry_type: "confirmed_booking",
  title: "Vogue Editorial Shoot",
  notes: "Day 1 of Summer Campaign",
  location: "Studio 54, Manhattan",
  starts_at: now + 7.days,
  ends_at: now + 7.days + 8.hours,
  status: "active",
  source: project1
)

ScheduleEntry.create!(
  user: pro1,
  created_by: manager,
  entry_type: "confirmed_booking",
  title: "Vogue Editorial Shoot - Day 2",
  notes: "Day 2 of Summer Campaign",
  location: "Studio 54, Manhattan",
  starts_at: now + 8.days,
  ends_at: now + 8.days + 8.hours,
  status: "active",
  source: project1
)

ScheduleEntry.create!(
  user: pro1,
  created_by: pro1,
  entry_type: "available",
  title: "Available - Morning",
  starts_at: now + 10.days,
  ends_at: now + 10.days + 4.hours,
  status: "active"
)

ScheduleEntry.create!(
  user: pro1,
  created_by: pro1,
  entry_type: "not_available",
  title: "Family Event",
  notes: "Personal commitment - unavailable",
  starts_at: now + 12.days,
  ends_at: now + 12.days + 12.hours,
  status: "active"
)

ScheduleEntry.create!(
  user: pro1,
  created_by: manager,
  entry_type: "tentative_booking",
  title: "H&M Casting",
  location: "Casting House, Brooklyn",
  notes: "Tentative - awaiting confirmation",
  starts_at: now + 3.days + 10.hours,
  ends_at: now + 3.days + 12.hours,
  status: "active",
  requires_rsvp: true
)

ScheduleEntry.create!(
  user: pro1,
  created_by: pro1,
  entry_type: "travel",
  title: "Travel to LA",
  notes: "Flight AA123 to Los Angeles",
  starts_at: now + 13.days,
  ends_at: now + 13.days + 6.hours,
  status: "active"
)

# ---- Schedule Entries for Maya ----
ScheduleEntry.create!(
  user: pro2,
  created_by: manager,
  entry_type: "confirmed_booking",
  title: "Nike Campaign - Shoot Day 1",
  location: "Venice Beach, LA",
  starts_at: now + 14.days,
  ends_at: now + 14.days + 10.hours,
  status: "active",
  source: project2
)

ScheduleEntry.create!(
  user: pro2,
  created_by: pro2,
  entry_type: "busy",
  title: "Acting class",
  starts_at: now + 2.days + 9.hours,
  ends_at: now + 2.days + 11.hours,
  status: "active"
)

rsvp_entry = ScheduleEntry.create!(
  user: pro2,
  created_by: manager,
  entry_type: "hold",
  title: "Cosmetics Brand Callback",
  location: "Agency HQ",
  notes: "Please confirm attendance",
  starts_at: now + 4.days + 14.hours,
  ends_at: now + 4.days + 16.hours,
  status: "active",
  requires_rsvp: true
)

# ---- Schedule Entries for James ----
ScheduleEntry.create!(
  user: pro3,
  created_by: pro3,
  entry_type: "personal_block",
  title: "Gym / Personal Time",
  starts_at: now + 1.days + 7.hours,
  ends_at: now + 1.days + 9.hours,
  status: "active"
)

ScheduleEntry.create!(
  user: pro3,
  created_by: manager,
  entry_type: "shoot_work_day",
  title: "Commercial Film - Automotive Brand",
  location: "Location TBD",
  starts_at: now + 5.days,
  ends_at: now + 5.days + 12.hours,
  status: "active"
)

# ---- RSVP Participations ----
Participation.create!(
  user: pro2,
  schedule_entry: rsvp_entry,
  response: "yes",
  responded_at: now - 1.hour
)

# ---- Tasks ----
Task.create!(
  user: pro1,
  created_by: manager,
  title: "Submit portfolio update to agency",
  description: "Update comp card with latest Vogue campaign photos",
  task_type: "submission_deadline",
  due_date: Date.today + 5.days,
  priority: "high",
  status: "pending"
)

Task.create!(
  user: pro1,
  created_by: pro1,
  title: "Confirm wardrobe fitting for Vogue shoot",
  task_type: "preparation_reminder",
  due_date: Date.today + 6.days,
  priority: "medium",
  status: "pending"
)

Task.create!(
  user: pro1,
  created_by: manager,
  title: "Follow up on H&M casting feedback",
  task_type: "follow_up",
  due_date: Date.today + 2.days,
  priority: "medium",
  status: "in_progress"
)

Task.create!(
  user: pro2,
  created_by: manager,
  title: "Renew work permit",
  task_type: "submission_deadline",
  due_date: Date.today + 30.days,
  priority: "urgent",
  status: "pending"
)

Task.create!(
  user: pro2,
  created_by: pro2,
  title: "Prepare Nike brand brief",
  task_type: "preparation_reminder",
  due_date: Date.today + 13.days,
  priority: "high",
  status: "pending"
)

Task.create!(
  user: pro3,
  created_by: manager,
  title: "Sign exclusivity contract",
  task_type: "submission_deadline",
  due_date: Date.today + 1.day,
  priority: "urgent",
  status: "pending"
)

# ---- Assignments ----
Assignment.new(
  user: pro1,
  project: project1,
  title: "Vogue Summer Editorial",
  assignment_type: "assignment",
  scheduled_at: now + 7.days,
  ends_at: now + 7.days + 8.hours,
  location: "Studio 54, Manhattan",
  status: "confirmed"
).save!(validate: false)

Assignment.new(
  user: pro1,
  title: "H&M Autumn Casting",
  assignment_type: "audition",
  scheduled_at: now + 3.days + 10.hours,
  ends_at: now + 3.days + 12.hours,
  location: "Casting House, Brooklyn",
  status: "pending"
).save!(validate: false)

Assignment.new(
  user: pro2,
  project: project2,
  title: "Nike Campaign Athlete",
  assignment_type: "assignment",
  scheduled_at: now + 14.days,
  ends_at: now + 14.days + 10.hours,
  location: "Venice Beach, LA",
  status: "confirmed"
).save!(validate: false)

# ---- Notifications ----
Notification.create!(
  user: pro1,
  title: "New booking confirmed",
  body: "Sarah Chen confirmed your Vogue Editorial booking on #{(now + 7.days).strftime('%b %d')}",
  notification_type: "schedule_change",
  read: false
)

Notification.create!(
  user: pro1,
  title: "RSVP requested",
  body: "Please respond to H&M Casting on #{(now + 3.days).strftime('%b %d')}",
  notification_type: "rsvp_update",
  read: false
)

Notification.create!(
  user: pro1,
  title: "Task due soon",
  body: "Follow up on H&M casting feedback is due in 2 days",
  notification_type: "task_reminder",
  read: true
)

Notification.create!(
  user: pro2,
  title: "Schedule update",
  body: "Nike Campaign shoot confirmed for #{(now + 14.days).strftime('%b %d')}",
  notification_type: "schedule_change",
  read: false
)

Notification.create!(
  user: pro3,
  title: "Urgent: Contract needs signing",
  body: "Exclusivity contract must be signed by tomorrow",
  notification_type: "task_reminder",
  read: false
)

puts "Seed complete!"
puts "  Users: #{User.count} (1 manager, 3 professionals)"
puts "  Schedule Entries: #{ScheduleEntry.count}"
puts "  Tasks: #{Task.count}"
puts "  Projects: #{Project.count}"
puts "  Assignments: #{Assignment.count}"
puts "  Notifications: #{Notification.count}"
puts ""
puts "Login credentials:"
puts "  Manager:       sarah.manager@talent.co / password123"
puts "  Professional1: alex.johnson@model.com  / password123"
puts "  Professional2: maya.patel@talent.com   / password123"
puts "  Professional3: james.kim@actor.com     / password123"

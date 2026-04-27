class ScheduleEntry < ApplicationRecord
  include Auditable

  ENTRY_TYPES = %w[
    available not_available busy shoot_work_day travel
    personal_block hold tentative_booking confirmed_booking
  ].freeze

  STATUSES = %w[active cancelled].freeze

  belongs_to :user
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :source, polymorphic: true, optional: true

  has_many :participations, dependent: :destroy
  has_many :participants, through: :participations, source: :user
  has_many :tasks, dependent: :nullify
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :audit_logs, -> { where(auditable_type: "ScheduleEntry") },
           foreign_key: :auditable_id, primary_key: :id

  validates :entry_type, presence: true, inclusion: { in: ENTRY_TYPES }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :ends_after_starts

  before_save :check_conflicts
  after_create :notify_on_create
  after_update :notify_on_change

  scope :active, -> { where(status: "active") }
  scope :for_date_range, ->(from, to) {
    where("starts_at < ? AND ends_at > ?", to, from)
  }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :upcoming, -> { active.where("starts_at > ?", Time.current) }

  def cancel!(actor)
    update!(status: "cancelled", updated_by: actor)
    notifications.create!(
      user: user,
      title: "Schedule entry cancelled",
      body: "#{entry_type.humanize} on #{starts_at.strftime('%b %d')} has been cancelled",
      notification_type: "schedule_change"
    )
  end

  def conflicting_entries
    ScheduleEntry.active
                 .where(user_id: user_id)
                 .where.not(id: id)
                 .for_date_range(starts_at, ends_at)
                 .where.not(entry_type: %w[available not_available])
  end

  def has_conflicts?
    conflicting_entries.exists?
  end

  def rsvp_summary
    return nil unless requires_rsvp
    {
      yes: participations.where(response: "yes").count,
      no: participations.where(response: "no").count,
      maybe: participations.where(response: "maybe").count,
      pending: participations.where(response: "pending").count
    }
  end

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end

  def check_conflicts
    self.has_conflict = has_conflicts?
  end

  def notify_on_create
    return if user_id == created_by_id
    Notification.create!(
      user: user,
      title: "New schedule entry",
      body: "#{created_by.name} added #{entry_type.humanize} on #{starts_at.strftime('%b %d')}",
      notification_type: "schedule_change",
      notifiable: self
    )
  end

  def notify_on_change
    return unless saved_change_to_starts_at? || saved_change_to_ends_at? || saved_change_to_entry_type? || saved_change_to_status?
    return if user_id == updated_by_id

    Notification.create!(
      user: user,
      title: "Schedule entry updated",
      body: "Your #{entry_type.humanize} on #{starts_at.strftime('%b %d')} was updated",
      notification_type: "schedule_change",
      notifiable: self
    )
  end
end

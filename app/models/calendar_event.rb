class CalendarEvent < ApplicationRecord
  include Auditable

  EVENT_TYPES = %w[general meeting interview workshop conference other].freeze

  belongs_to :created_by, class_name: "User"
  has_many :schedule_entries, as: :source, dependent: :nullify

  validates :title, presence: true
  validates :starts_at, :ends_at, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :ends_after_starts

  after_create :create_linked_schedule_entry

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end

  def create_linked_schedule_entry
    ScheduleEntry.create!(
      user: created_by,
      created_by: created_by,
      entry_type: "busy",
      title: title,
      starts_at: starts_at,
      ends_at: ends_at,
      all_day: all_day,
      location: location,
      notes: description,
      source: self
    )
  end
end

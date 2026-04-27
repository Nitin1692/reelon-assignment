class Assignment < ApplicationRecord
  include Auditable

  TYPES = %w[assignment audition callback fitting rehearsal general].freeze
  STATUSES = %w[pending confirmed cancelled].freeze

  belongs_to :user
  belongs_to :project, optional: true
  has_many :schedule_entries, as: :source, dependent: :nullify

  validates :title, presence: true
  validates :assignment_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }

  after_create :create_linked_schedule_entry
  after_update :sync_linked_schedule_entry

  private

  def create_linked_schedule_entry
    return unless scheduled_at
    ScheduleEntry.create!(
      user: user,
      created_by: user,
      entry_type: entry_type_for_schedule,
      title: title,
      starts_at: scheduled_at,
      ends_at: ends_at || (scheduled_at + 2.hours),
      location: location,
      notes: notes,
      source: self
    )
  end

  def sync_linked_schedule_entry
    return unless saved_change_to_scheduled_at? || saved_change_to_ends_at? || saved_change_to_status?
    linked = schedule_entries.first
    return unless linked

    if status == "cancelled"
      linked.cancel!(user)
    elsif scheduled_at
      linked.update!(
        starts_at: scheduled_at,
        ends_at: ends_at || (scheduled_at + 2.hours),
        updated_by: user
      )
    end
  end

  def entry_type_for_schedule
    case assignment_type
    when "audition", "callback" then "tentative_booking"
    when "assignment"           then "confirmed_booking"
    else "busy"
    end
  end
end

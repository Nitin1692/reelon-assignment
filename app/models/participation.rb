class Participation < ApplicationRecord
  include Auditable

  RESPONSES = %w[pending yes no maybe].freeze

  belongs_to :user
  belongs_to :schedule_entry

  validates :response, inclusion: { in: RESPONSES }
  validates :user_id, uniqueness: { scope: :schedule_entry_id }

  before_save :set_responded_at
  after_save :notify_organizer

  scope :responded, -> { where.not(response: "pending") }

  private

  def set_responded_at
    self.responded_at = Time.current if response_changed? && response != "pending"
  end

  def notify_organizer
    return unless saved_change_to_response?
    organizer = schedule_entry.created_by
    return if organizer == user

    Notification.create!(
      user: organizer,
      title: "RSVP update",
      body: "#{user.name} responded #{response} to #{schedule_entry.entry_type.humanize}",
      notification_type: "rsvp_update",
      notifiable: schedule_entry
    )
  end
end

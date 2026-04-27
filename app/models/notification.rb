class Notification < ApplicationRecord
  TYPES = %w[schedule_change conflict rsvp_update task_reminder assignment].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, :notification_type, presence: true
  validates :notification_type, inclusion: { in: TYPES }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_read!
    update!(read: true)
  end
end

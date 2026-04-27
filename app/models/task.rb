class Task < ApplicationRecord
  include Auditable

  TASK_TYPES = %w[submission_deadline preparation_reminder follow_up checklist general].freeze
  STATUSES = %w[pending in_progress completed cancelled].freeze
  PRIORITIES = %w[low medium high urgent].freeze

  belongs_to :user
  belongs_to :created_by, class_name: "User"
  belongs_to :schedule_entry, optional: true

  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :title, presence: true
  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  before_save :set_completed_at

  scope :pending, -> { where(status: "pending") }
  scope :active, -> { where(status: %w[pending in_progress]) }
  scope :overdue, -> { active.where("due_date < ?", Date.today) }
  scope :due_today, -> { active.where(due_date: Date.today) }
  scope :due_this_week, -> { active.where(due_date: Date.today..Date.today + 7.days) }

  def complete!(actor = nil)
    update!(status: "completed", completed_at: Time.current)
  end

  def overdue?
    due_date.present? && due_date < Date.today && %w[pending in_progress].include?(status)
  end

  private

  def set_completed_at
    self.completed_at = Time.current if status_changed? && status == "completed" && completed_at.nil?
  end
end

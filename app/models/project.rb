class Project < ApplicationRecord
  include Auditable

  belongs_to :created_by, class_name: "User"
  has_many :assignments, dependent: :destroy
  has_many :schedule_entries, as: :source, dependent: :nullify

  validates :title, presence: true
  validates :status, inclusion: { in: %w[active completed cancelled] }

  after_create :create_linked_schedule_entry

  scope :active, -> { where(status: "active") }

  private

  def create_linked_schedule_entry
    return unless starts_at && ends_at
    ScheduleEntry.create!(
      user: created_by,
      created_by: created_by,
      entry_type: "shoot_work_day",
      title: "Project: #{title}",
      starts_at: starts_at,
      ends_at: ends_at,
      source: self,
      notes: description
    )
  end
end

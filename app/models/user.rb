class User < ApplicationRecord
  has_secure_password

  ROLES = %w[professional manager admin].freeze

  has_many :schedule_entries, dependent: :destroy
  has_many :created_schedule_entries, class_name: "ScheduleEntry", foreign_key: :created_by_id, dependent: :nullify
  has_many :participations, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :created_tasks, class_name: "Task", foreign_key: :created_by_id, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :audit_logs, dependent: :nullify

  # Manager relationships
  has_many :manager_relationships, class_name: "UserRelationship", foreign_key: :manager_id, dependent: :destroy
  has_many :managed_professionals, through: :manager_relationships, source: :professional

  # Professional relationships (this user is managed by someone)
  has_many :professional_relationships, class_name: "UserRelationship", foreign_key: :professional_id, dependent: :destroy
  has_many :managers, through: :professional_relationships, source: :manager

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  before_save { self.email = email.downcase }

  def manager?
    role == "manager" || role == "admin"
  end

  def professional?
    role == "professional"
  end

  def admin?
    role == "admin"
  end

  def can_manage?(target_user)
    return true if admin?
    manager? && managed_professionals.include?(target_user)
  end
end

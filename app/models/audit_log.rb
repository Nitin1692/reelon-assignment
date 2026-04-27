class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :auditable_type, :auditable_id, :action, presence: true

  scope :for_record, ->(type, id) { where(auditable_type: type, auditable_id: id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  def changes_hash
    JSON.parse(changes_data || "{}")
  rescue JSON::ParserError
    {}
  end
end

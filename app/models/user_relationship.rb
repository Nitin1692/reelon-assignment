class UserRelationship < ApplicationRecord
  belongs_to :manager, class_name: "User"
  belongs_to :professional, class_name: "User"

  validates :manager_id, uniqueness: { scope: :professional_id }
  validate :manager_must_have_manager_role
  validate :cannot_manage_self

  private

  def manager_must_have_manager_role
    return unless manager
    errors.add(:manager, "must have manager or admin role") unless manager.manager?
  end

  def cannot_manage_self
    errors.add(:base, "A user cannot manage themselves") if manager_id == professional_id
  end
end

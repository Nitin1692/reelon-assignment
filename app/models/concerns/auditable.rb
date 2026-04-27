module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  :audit_create
    after_update  :audit_update
    after_destroy :audit_destroy
  end

  private

  def audit_create
    create_audit("created", nil, attributes)
  end

  def audit_update
    return if saved_changes.blank?
    create_audit("updated", saved_changes.transform_values(&:first), saved_changes.transform_values(&:last))
  end

  def audit_destroy
    create_audit("deleted", attributes, nil)
  end

  def create_audit(action, previous, current)
    AuditLog.create!(
      auditable_type: self.class.name,
      auditable_id: id,
      user_id: Current.user&.id,
      action: action,
      changes_data: { previous: previous, current: current }.to_json
    )
  rescue => e
    Rails.logger.error("Audit log failed: #{e.message}")
  end
end

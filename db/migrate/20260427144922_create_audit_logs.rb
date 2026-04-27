class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      # created | updated | cancelled | rsvp_changed | deleted
      t.text :changes_data
      t.text :metadata
      t.string :ip_address

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :user_id
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end

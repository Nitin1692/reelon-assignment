class AddAllColumnsToScheduleEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :schedule_entries, :user, foreign_key: true
    add_reference :schedule_entries, :created_by, foreign_key: { to_table: :users }
    add_reference :schedule_entries, :updated_by, foreign_key: { to_table: :users }
    add_column :schedule_entries, :entry_type, :string
    add_column :schedule_entries, :title, :string
    add_column :schedule_entries, :notes, :text
    add_column :schedule_entries, :location, :string
    add_column :schedule_entries, :starts_at, :datetime
    add_column :schedule_entries, :ends_at, :datetime
    add_column :schedule_entries, :all_day, :boolean, default: false
    add_column :schedule_entries, :status, :string, default: "active"
    add_column :schedule_entries, :requires_rsvp, :boolean, default: false
    add_column :schedule_entries, :source_type, :string
    add_column :schedule_entries, :source_id, :bigint
    add_column :schedule_entries, :has_conflict, :boolean, default: false

    add_index :schedule_entries, [:user_id, :starts_at, :ends_at]
    add_index :schedule_entries, :entry_type
    add_index :schedule_entries, :status
    add_index :schedule_entries, [:source_type, :source_id]
    add_index :schedule_entries, :starts_at
  end
end

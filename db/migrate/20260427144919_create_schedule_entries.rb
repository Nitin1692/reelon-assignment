class CreateScheduleEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: true, foreign_key: { to_table: :users }

      # Entry classification
      t.string :entry_type, null: false
      # available | not_available | busy | shoot_work_day | travel |
      # personal_block | hold | tentative_booking | confirmed_booking

      t.string :title
      t.text :notes
      t.string :location

      # Timing
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, default: false

      # Lifecycle
      t.string :status, null: false, default: "active"
      # active | cancelled

      # RSVP
      t.boolean :requires_rsvp, default: false

      # Polymorphic link to source object (project/assignment/calendar_event)
      t.string :source_type
      t.bigint :source_id

      # Conflict tracking
      t.boolean :has_conflict, default: false

      t.timestamps
    end

    add_index :schedule_entries, [:user_id, :starts_at, :ends_at]
    add_index :schedule_entries, :entry_type
    add_index :schedule_entries, :status
    add_index :schedule_entries, [:source_type, :source_id]
    add_index :schedule_entries, :starts_at
  end
end

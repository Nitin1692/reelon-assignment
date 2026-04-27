class CreateCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :location
      t.string :event_type, default: "general"
      t.boolean :all_day, default: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :calendar_events, :starts_at
    add_index :calendar_events, :event_type
  end
end

class AddMissingColumnsToCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :calendar_events, :event_type, :string, default: "general"
    add_column :calendar_events, :all_day, :boolean, default: false

    add_index :calendar_events, :starts_at
    add_index :calendar_events, :event_type
  end
end

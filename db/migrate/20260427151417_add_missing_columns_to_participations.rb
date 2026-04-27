class AddMissingColumnsToParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :participations, :note, :text
    add_column :participations, :responded_at, :datetime
  end
end

class CreateParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :schedule_entry, null: false, foreign_key: true
      t.string :response, null: false, default: "pending"
      # pending | yes | no | maybe
      t.text :note
      t.datetime :responded_at

      t.timestamps
    end

    add_index :participations, [:user_id, :schedule_entry_id], unique: true
    add_index :participations, :response
  end
end

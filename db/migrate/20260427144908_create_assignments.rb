class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :assignment_type, default: "assignment"
      t.datetime :scheduled_at
      t.datetime :ends_at
      t.string :location
      t.string :status, default: "pending"
      t.text :notes

      t.timestamps
    end

    add_index :assignments, :status
    add_index :assignments, :assignment_type
  end
end

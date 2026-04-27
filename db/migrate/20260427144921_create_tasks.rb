class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :schedule_entry, null: true, foreign_key: true

      t.string :title, null: false
      t.text :description
      t.string :task_type, default: "general"
      # submission_deadline | preparation_reminder | follow_up | checklist | general

      t.date :due_date
      t.time :due_time
      t.string :priority, default: "medium"
      # low | medium | high | urgent

      t.string :status, default: "pending"
      # pending | in_progress | completed | cancelled

      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
    add_index :tasks, :task_type
    add_index :tasks, :priority
  end
end

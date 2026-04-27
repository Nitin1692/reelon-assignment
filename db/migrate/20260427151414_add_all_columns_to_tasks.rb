class AddAllColumnsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :user, foreign_key: true
    add_reference :tasks, :created_by, foreign_key: { to_table: :users }
    add_reference :tasks, :schedule_entry, foreign_key: true
    add_column :tasks, :title, :string
    add_column :tasks, :description, :text
    add_column :tasks, :task_type, :string, default: "general"
    add_column :tasks, :due_date, :date
    add_column :tasks, :due_time, :time
    add_column :tasks, :priority, :string, default: "medium"
    add_column :tasks, :status, :string, default: "pending"
    add_column :tasks, :completed_at, :datetime

    add_index :tasks, :status
    add_index :tasks, :due_date
    add_index :tasks, :task_type
    add_index :tasks, :priority
  end
end

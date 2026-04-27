class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :notification_type, null: false
      # schedule_change | conflict | rsvp_update | task_reminder | assignment
      t.boolean :read, default: false
      t.string :notifiable_type
      t.bigint :notifiable_id

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, :notification_type
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end

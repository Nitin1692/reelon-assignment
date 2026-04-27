class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :status, default: "active"
      t.string :category
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :projects, :status
  end
end

class CreateUserRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :user_relationships do |t|
      t.references :manager, null: false, foreign_key: { to_table: :users }
      t.references :professional, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :user_relationships, [:manager_id, :professional_id], unique: true
  end
end

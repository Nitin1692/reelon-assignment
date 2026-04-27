class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "professional"
      t.string :password_digest, null: false
      t.string :phone
      t.string :avatar_url
      t.string :timezone, default: "UTC"
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end

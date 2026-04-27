class AddMissingColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone, :string
    add_column :users, :avatar_url, :string
    add_column :users, :timezone, :string, default: "UTC"
    add_column :users, :active, :boolean, default: true, null: false
  end
end

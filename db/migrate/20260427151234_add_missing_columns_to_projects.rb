class AddMissingColumnsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :status, :string, default: "active"
    add_column :projects, :category, :string
  end
end

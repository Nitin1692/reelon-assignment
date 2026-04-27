class AddMissingColumnsToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :assignment_type, :string, default: "assignment"
    add_column :assignments, :ends_at, :datetime
    add_column :assignments, :status, :string, default: "pending"
    add_column :assignments, :notes, :text

    add_index :assignments, :status
    add_index :assignments, :assignment_type
  end
end

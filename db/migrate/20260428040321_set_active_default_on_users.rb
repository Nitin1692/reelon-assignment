class SetActiveDefaultOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :active, from: nil, to: true
    User.where(active: nil).update_all(active: true)
  end
end

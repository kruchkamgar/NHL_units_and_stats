class AddActionTypeToLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :action_type, :string
  end
end

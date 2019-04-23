class AddActionTypeToLogEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :log_entries, :action_type, :string
  end
end

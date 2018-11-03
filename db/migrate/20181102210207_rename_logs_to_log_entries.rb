class RenameLogsToLogEntries < ActiveRecord::Migration[5.2]
  def up
    rename_table :logs, :log_entries
  end

  def down
    rename_table :log_entries, :logs
  end
end

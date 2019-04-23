class RemovePlayerIdFromLogEntries < ActiveRecord::Migration[5.2]
  def change
    remove_column :log_entries, :player_id, :integer
  end
end

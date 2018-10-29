class RemovePlayerIdFromLogs < ActiveRecord::Migration[5.2]
  def change
    remove_column :logs, :player_id, :integer
  end
end

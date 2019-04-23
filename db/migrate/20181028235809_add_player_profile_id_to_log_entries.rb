class AddPlayerProfileIdToLogEntries < ActiveRecord::Migration[5.2]
  def change
    add_reference :log_entries, :player_profile
  end
end

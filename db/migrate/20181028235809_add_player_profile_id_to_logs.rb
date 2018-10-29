class AddPlayerProfileIdToLogs < ActiveRecord::Migration[5.2]
  def change
    add_reference :logs, :player_profile, foreign_key: true
  end
end

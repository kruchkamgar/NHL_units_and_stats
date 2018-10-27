class AddPlayerIdToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :player_id, :integer
  end
end

class AddIndexToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_index :players, :player_id_num, unique: true
  end
end

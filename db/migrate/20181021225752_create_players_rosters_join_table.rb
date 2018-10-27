class CreatePlayersRostersJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :players, :rosters do |t|
      t.index [:player_id, :roster_id]
      t.index [:roster_id, :player_id]
    end
  end
end

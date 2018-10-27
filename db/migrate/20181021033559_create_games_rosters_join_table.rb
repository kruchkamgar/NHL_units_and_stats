class CreateGamesRostersJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :games, :rosters do |t|
      t.index [:game_id, :roster_id]
      t.index [:roster_id, :game_id]
    end
  end
end

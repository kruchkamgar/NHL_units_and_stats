class CreateGamesUnitsJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :games, :units do |t|
      t.index [:game_id, :unit_id]
      t.index [:unit_id, :game_id]
    end
  end
end

class CreateJoinTableGamesPlayerProfiles < ActiveRecord::Migration[5.2]
  def change
    create_join_table :games, :player_profiles do |t|
      # t.index [:game_id, :player_profile_id]
      # t.index [:player_profile_id, :game_id]
    end
  end
end

require_relative './team_hash'

def sample_players
  [
    { id: 1, first_name: "Bill", last_name: "Williams", player_id_num: 101 },
    { id: 2, first_name: "Frances", last_name: "Baggins", player_id_num: 102 },
    { id: 3, first_name: "Jacques", last_name: "Cousteau", player_id_num: 103 }
  ]
end

# used by: create_roster_spec, NHL_game_events_api_spec
def sample_profiles
  team_hash_02["players"].first(3).
  map.with_index do |id, index|
    plyr_hash = team_hash_02["players"]["#{id[0]}"]

    PlayerProfile.new(
      id: (index + @init_index),
      position: plyr_hash["position"]["name"],
      position_type: plyr_hash["position"]["type"],
      player_id: (index + @init_index)
    )
  end
end

def team_hash_players
   team_hash["players"].
   map.with_index do |id, index|
      plyr_hash = team_hash["players"]["#{id[0]}"]
      Player.new(
        id: (index+1),
        first_name: plyr_hash["firstName"],
        last_name: plyr_hash["lastName"],
        player_id_num: plyr_hash["person"]["id"]
      )
    end
end

def team_hash_player_profiles
  team_hash["players"].
  map.with_index do |id, index|
    plyr_hash = team_hash["players"]["#{id[0]}"]

    PlayerProfile.new(
      id: (index+1),
      position: plyr_hash["position"]["name"],
      position_type: plyr_hash["position"]["type"],
      player_id: (index+1)
    )
  end
end

team_hash_players.
each_with_index do |player, i|
  player.player_profiles << team_hash_player_profiles[i]
end

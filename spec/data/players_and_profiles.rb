require_relative './team_hash'

def sample_players
  [
    { first_name: "Bill", last_name: "Williams", player_id_num: 101 },
    { first_name: "Frances", last_name: "Baggins", player_id_num: 102 },
    { first_name: "Jacques", last_name: "Cousteau", player_id_num: 103 }
  ]
end

def sample_profiles
  [
    { id: 1, player_id: 101, position: "Defenseman", position_type: "Defenseman", created_at: nil, updated_at: nil},
    { id: 2, player_id: 102, position: "Right Wing", position_type: "Forward" },
    { id: 3, player_id: 103, position: "Defenseman", position_type: "Defenseman" }
  ]
end

def team_hash_players
   team_hash["players"].
   map.with_index(1) do |id, index|
      plyr_hash = team_hash["players"]["#{id[0]}"]
      Player.new(
        id: index,
        first_name: plyr_hash["firstName"],
        last_name: plyr_hash["lastName"],
        player_id_num: plyr_hash["person"]["id"]
      )
    end
end

def team_hash_player_profiles
  team_hash["players"].
  map.with_index(1) do |id, index|
    plyr_hash = team_hash["players"]["#{id[0]}"]

    PlayerProfile.new(
      id: index,
      position: plyr_hash["position"]["name"],
      position_type: plyr_hash["position"]["type"],
      player_id: index
    )
  end
end

team_hash_players.
each_with_index do |player, i|
  player.player_profiles << team_hash_player_profiles[i]
end

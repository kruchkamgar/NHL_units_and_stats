def sample_players
  sample_players = [
    { first_name: "Bill", last_name: "Williams", player_id_num: 1 },
    { first_name: "Frances", last_name: "Baggins", player_id_num: 2 },
    { first_name: "Jacques", last_name: "Cousteau", player_id_num: 3 }
  ]
end

def sample_profiles
  [
    { id: 1, player_id: 1, position: "Defenseman", position_type: "Defenseman", created_at: nil, updated_at: nil},
    { id: 2, player_id: 2, position: "Right Wing", position_type: "Forward" },
    { id: 3, player_id: 3, position: "Defenseman", position_type: "Defenseman" }
  ]
end

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require './spec/data/team_hash'
require './spec/data/create_events_from_hashes'
# require './lib/utilities.rb'

def run_seeds
  destroy_all_db
  create_and_associate_profiles_and_players
  create_game
  create_team
  create_roster
  create_events_sampling
  create_instances
end

def destroy_all_db
  LogEntry.destroy_all
  Circumstance.destroy_all

  Event.destroy_all
  PlayerProfile.destroy_all
  Instance.destroy_all

  Tally.destroy_all
  Unit.destroy_all

  Player.destroy_all
  Game.destroy_all
  Roster.destroy_all
  Team.destroy_all

  ApplicationRecord.connection.execute("DELETE FROM games_units")

  ApplicationRecord.connection.execute("DELETE FROM games_rosters")
  ApplicationRecord.connection.execute("DELETE FROM players_rosters")
  ApplicationRecord.connection.execute("DELETE FROM rosters_units")

  ApplicationRecord.connection.execute("DELETE FROM events_instances")
end

def team_hash_players
   team_hash["players"].
   map.with_index(1) do |id, index|
      plyr_hash = team_hash["players"]["#{id[0]}"]["person"]
      Player.find_or_create_by(
        id: index,
        first_name: plyr_hash["firstName"],
        last_name: plyr_hash["lastName"],
        player_id_num: plyr_hash["id"]
      )
    end
end

def team_hash_player_profiles
  team_hash["players"].
  map.with_index(1) do |id, index|
    plyr_hash = team_hash["players"]["#{id[0]}"]

    PlayerProfile.find_or_create_by(
      id: index,
      position: plyr_hash["position"]["name"],
      position_type: plyr_hash["position"]["type"],
      player_id: index
    )
  end
end

def create_and_associate_profiles_and_players
  profiles = team_hash_player_profiles
  team_hash_players.
  each_with_index do |player, i|
    player.player_profiles << profiles[i]
  end
end

def create_game
  game = Game.create(id: 1, home_side: "New Jersey Devils", game_id: 2017020019)

  game.player_profiles << team_hash_player_profiles #find_or_create_by
end

def create_team
  Team.create(id:1, name: "New Jersey Devils", team_id: 1)
end

def create_roster
  roster = Roster.create(team_id: 1)
  roster.players << team_hash_players #find_or_create_by
end

def create_events_sampling

  ( events_hashes[0..-20].
    sample(5) +
    all_goal_events ).
  each do |event|
    Event.find_or_create_by(
      event_type: event["eventDescription"] || "shift", duration: event["duration"],
      start_time: event["startTime"],
      end_time: event["endTime"],
      shift_number: event["shiftNumber"],
      period: event["period"],
      player_id_num: event["playerId"],
      game_id: 1
    )
  end
end

def create_instances
  all_goal_events.each do |event|
    instance =
    Instance.find_or_create_by(
      duration: "01:00",
      start_time: Utilities::TimeOperation.new(:-, "00:30", event["startTime"]).result
    )

    add_events_to_instance (instance)
  end
end

# //////////////// helper methods ///////////////// #
def add_events_to_instance (instance)
  instance_end_time =
  Utilities::TimeOperation.new(:+, instance.duration, instance.start_time).result

  concurrent_events =
  Event.
  where.not(event_type: "shift").
  select do |event|
    event.end_time > instance.start_time && event.end_time <= instance_end_time
  end

  instance.events << concurrent_events
end


run_seeds

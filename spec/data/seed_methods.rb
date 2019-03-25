require_relative './seed_team_hashes.rb'
require_relative './data'
# issue: odd namespace collisions with ./players_and_profiles.rb

# set—-
  # @team_id
  # @game_id
  # @team_hash

module SeedMethods
include SeedTeamHashes

# set without using data.rb
  # def set_team_hash (team: :team_hash_devils)
  #   # if devils
  #     # @team_id = 1 ...
  #     # @game_id = __ unless @game_id  end
  #   @team_hash = method(team).call
  # end

  def create_team
    @team = Team.create(name: "New Jersey Devils", team_id: @team_id)
  end

  def create_and_associate_profiles_and_players
    players = team_players
    profiles = team_player_profiles
    players
    .each_with_index do |player, i|
      player.player_profiles << profiles[i] end

    create_roster(players)
    [players, profiles]
  end

  def team_players
    @team_hash["players"]
    .map.with_index(1) do |id, index|
      plyr_hash = @team_hash["players"]["#{id[0]}"]["person"]
      Player.find_or_create_by(
        id: index,
        first_name: plyr_hash["firstName"],
        last_name: plyr_hash["lastName"],
        player_id_num: plyr_hash["id"] )
    end
  end #team_players

  def team_player_profiles
    @team_hash["players"]
    .map.with_index(1) do |id, index|
      plyr_hash = @team_hash["players"]["#{id[0]}"]

      PlayerProfile.find_or_create_by(
        id: index,
        position: plyr_hash["position"]["name"],
        position_type: plyr_hash["position"]["type"],
        player_id: index ) end
  end

  def create_roster(players = nil)
    @roster = Roster.create(team_id: @team_id)
    @roster.players << ( players || team_players ) #find_or_create_by
  end


  def create_game (player_profiles = nil)
    @game =
    Game.find_or_create_by(home_side: "New Jersey Devils", game_id: @game_id)

    @game.player_profiles << player_profiles #find_or_create_by
  end

  def create_events
    all_goal_events
    .each do |event|
      Event.find_or_create_by(
        event_type: event["eventDescription"] || "shift", duration: event["duration"],
        start_time: event["startTime"],
        end_time: event["endTime"],
        shift_number: event["shiftNumber"],
        period: event["period"],
        player_id_num: event["playerId"],
        game_id: @game.id ) end
  end

  def shift_events_by_team
    events_by_team - goal_events
  end

  def goal_events
    events_by_team
    .select do |event|
      event["typeCode"] == 505
    end
  end

  def all_goal_events
    @events_hashes
    .select do |event|
      event["typeCode"] == 505
    end
  end

  def events_by_team
    @events_hashes
    .select do |event|
      event["teamId"] == @team.team_id
    end
  end

  # mock instances
  def create_instances
    all_goal_events
    .each do |event|
      instance =
      Instance.find_or_create_by(
        duration: "01:00",
        start_time: Utilities::TimeOperation.new(:-, event["startTime"], "00:30" ).result )

      add_events_to_instance(instance)
    end
  end

  # //////////////// helper methods ///////////////// #
  def add_events_to_instance (instance)
    instance_end_time =
    Utilities::TimeOperation.new(:+, instance.duration, instance.start_time).result

    concurrent_events =
    Event
    .where.not(event_type: "shift")
    .select do |event|
      event.end_time > instance.start_time && event.end_time <= instance_end_time
    end

    instance.events << concurrent_events
  end

end # TestMethods

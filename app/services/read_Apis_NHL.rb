module ReadApisNHL
  include NHLTeamAPI

  #  create class/ Adapter for each team, process games only once per team (@@games)
    # -- can then replace NHLGameEventsAPI gate

  def create_teams_for_season
    get_season
    create_all_teams_by_season() unless Team.find_by(season: @season)
  end

  def create_roster(game, teams_hash)
    teams_data =
    teams_hash.
    map do |side, side_hash|
      [ side_hash["team"]["id"],
        side_hash ] end
    hashed =
    Hash[
      ids: teams_data.transpose.first,
      hash_data: teams_data.transpose.second ]
    team_records =
    Team.where(team_id: hashed[:ids])
    hashed[:hash_data].
    map do |hash|
      team_record =
      team_records.
      find_by(team_id: hash["team"]["id"] )
      [ team_record, hash ] end.
    map do |team, hash|
      CreateRoster::create_game_roster(
        hash, team, game )
    end
  end

  def read_NHL_APIs

    create_teams_for_season
    # create team and get its schedule
    @team, team_adapter = NHLTeamAPI::Adapter.new(team_id: 1).create_team
    schedule_hash =
    team_adapter.fetch_data
    # create a game for each schedule date
    schedule_hash["dates"].
    reject do |date|
      # "1" means preseason
      date["games"].first["gamePk"].to_s.
      slice(5) == "1" end.
    each do |date_hash|
      game_id = date_hash["games"].first["gamePk"]
      unless game_id then byebug end

      game, teams_hash =
      NHLGameAPI::Adapter.
      new(game_id: 2018020048).
      create_game
      # game API may deliver two teams' players

      rosters = create_roster(game, teams_hash)

      roster = rosters.find do |roster|
        roster.team.eql?(@team) end

      events_boolean =
      NHLGameEventsAPI::Adapter.
      new(team:
        @team, game: game, roster: roster).
      create_game_events_and_log_entries # *1

      byebug
      if events_boolean
        CreateUnitsAndInstances.
        create_records_from_shifts(@team, roster, game)

        ProcessSpecialEvents.
        process_special_events(@team, roster, game)
      end
    end # .each

    # create the main roster
    # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster

  end

  # ////////////// helpers /////////////// #

  def select_team_hash (teams_hash, team_id = nil)
    team_id ||= @team.team_id

    teams_hash.select { |side|
      teams_hash[side]["team"]["id"] == team_id
    }.first[1]
  end

  module_function :select_team_hash, :read_NHL_APIs, :create_teams_for_season
end


# *1 -
#  (improvement) store record of games processed, to track events already inserted. also [to conceivably allow for mutation of (external) API game data] track the results of ProcessSpecialEvents per game

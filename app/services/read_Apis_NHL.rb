module ReadApisNHL
  TEAMS =
  Hash[
    1 => "New Jersey Devils",
    2 => "New York Islanders"
  ]

  def read_NHL_APIs
    # create team and get its schedule
    @team, team_adapter = NHLTeamAPI::Adapter.new(team_id: 1).create_team
    schedule_hash =
    team_adapter.fetch_data
    # create a game for each schedule date
    schedule_hash["dates"].
    reject do |date|
      date["games"].first["gamePk"].to_s.
      slice(5) == "1" end.  # 1 means preseason
    each do |date_hash|
      game_id = date_hash["games"].first["gamePk"]
      unless game_id then byebug end

      game, teams_hash =
      NHLGameAPI::Adapter.new(game_id: game_id).create_game
      # game API may deliver two teams' players
      roster =
      CreateRoster::create_game_roster(
        select_team_hash(teams_hash),
        @team, game
      )
      events_boolean =
      NHLGameEventsAPI::Adapter.new(team:
        @team, game: game, roster: roster).create_game_events_and_log_entries

      byebug
      CreateUnitsAndInstances.create_records_from_shifts(@team, roster, game) if events_boolean

      ProcessSpecialEvents.process_special_events(@team, roster, game)
    end

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

  module_function :select_team_hash, :read_NHL_APIs
end

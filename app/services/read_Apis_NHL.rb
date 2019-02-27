module ReadApisNHL

  #  create class/ Adapter for each team, to enable processing games only once per team (@processed_games)
    # -- can then replace NHLGameEventsAPI gate

include NHLTeamAPI
  def create_teams_for_season
    get_season
    create_all_teams_by_season() unless Team.find_by(season: @season)
  end

  def create_full_season
    teams = Team.where(season: 20182019)
    if teams.empty?
      create_teams_for_season() end


    teams.
    each do |team|
      @team_season =
      TeamSeason.new(season: 20182018, team: team)
      @team_season.create_records_from_APIs
      @team_season.create_tallies
    end
  end

  class TeamSeason

    def initialize (season:, team:)
      @season, @team_id = season, team.team_id
      @units_includes_events = []
    end

  include ReadApisNHL
    def create_records_from_APIs
      # create_teams_for_season()
      # create team and get its schedule
      @team, team_adapter = NHLTeamAPI::Adapter.new(team_id: @team_id).create_team

      schedule_hash = team_adapter.fetch_data
      get_schedule_dates(schedule_hash).
      each do |date_hash|
        create_game_records(date_hash); break; end
    end

    def get_schedule_dates(schedule_hash)
      schedule_hash["dates"].
      reject do |date|
        # "1" means preseason
        date["games"].first["gamePk"].to_s.
        slice(5) == "1" end
    end

    def create_game_records(date_hash)
    # create a game for each schedule date
      game_id =
      date_hash["games"].first["gamePk"]
      unless game_id then byebug end

      game, teams_hash =
      NHLGameAPI::Adapter.
      new(game_id: game_id).
      create_game
      # game API may deliver two teams' players

      rosters = create_rosters(game, teams_hash)
      roster =
      rosters.find do |roster|
        roster.team.eql?(@team) end

      events_boolean =
      NHLGameEventsAPI::Adapter.
      new(team:
        @team, game: game, roster: roster).
      create_game_events_and_log_entries # *1

      # byebug
      if events_boolean
        @units_includes_events = CreateUnitsAndInstances.
        create_records_from_shifts(@team, roster, game, @units_includes_events)

        ProcessSpecialEvents.
        process_special_events(@team, roster, game, @units_includes_events)
      end
    end #create_game_records

    # create the main roster
    # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster
    def create_rosters(game, teams_hash)
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

    def create_tallies
      prepared_tallies =
      @units_includes_events.
      map do |unit|
        tally = unit.build_tally
        tally.tally_unit
        byebug if $interrupt
        Hash[
          unit_id: unit.id,
          assists: tally.assists,
          plus_minus: tally.plus_minus,
          goals: tally.goals,
          points: tally.points,
          created_at: Time.now,
          updated_at: Time.now ]
      end

      SQLOperations.sql_insert_all("tallies", prepared_tallies)
    end
  end #TeamSeason


  # ////////////// helpers /////////////// #

  # def select_team_hash (teams_hash, team_id = nil)
  #   team_id ||= @team.team_id
  #
  #   teams_hash.select { |side|
  #     teams_hash[side]["team"]["id"] == team_id
  #   }.first[1]
  # end

  module_function :create_full_season, :create_teams_for_season
end


# *1 -
#  (improvement) store record of games processed, to track events already inserted. also [to conceivably allow for mutation of (external) API game data] track the results of ProcessSpecialEvents per game

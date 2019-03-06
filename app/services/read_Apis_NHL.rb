module ReadApisNHL

  #  create class/ Adapter for each team, to enable processing games only once per team (@processed_games)
    # -- can then replace NHLGameEventsAPI gate
$season = 20182019

include NHLTeamAPI
  def create_teams_seasons
    teams =
    Team.left_outer_joins(rosters: [:units])
    .where(season: $season)
    .group("teams.id").having("COUNT(units.id) = 0")

    if teams.empty?
      create_teams_for_season() end

    teams.
    each do |team|
      @team_season =
      TeamSeason.new(season: $season, team: team)
      @team_season.create_records_from_APIs
      @team_season.create_tallies
      byebug
    end
  end

  # teams to which to associate opposing team rosters, per game
  def create_teams_for_season
    get_season
    create_all_teams_by_season() unless Team.find_by(season: @season)
  end

  class TeamSeason

    def initialize (season:, team:)
      @season, @team = season, team
    end

  include ReadApisNHL
    def create_records_from_APIs
      # create_teams_for_season()
      # create team and get its schedule
      team_adapter =
      NHLTeamAPI::Adapter.new(team: @team)
      .find_or_create_team

      schedule_hash = team_adapter.fetch_data
      schedule_dates =
      get_schedule_dates(schedule_hash)[8..10]
      .select do |date|
        date["date"] < Time.now end

      schedule_dates
      .each do |date_hash|
        create_game_records(date_hash) end
    end

  include CreateUnitsAndInstances
  include ProcessSpecialEvents
    def create_game_records(date_hash)
    # create a game for each schedule date
      game_id =
      date_hash["games"].first["gamePk"]

      @game, teams_hash =
      NHLGameAPI::Adapter.
      new(game_id: game_id)
      .create_game
      # game API may deliver two teams' players

      rosters = create_rosters(@game, teams_hash)
      @roster =
      rosters.find do |roster|
        roster.team.eql?(@team) end

      events_boolean =
      NHLGameEventsAPI::Adapter
      .new(team:
        @team, game: @game )
      .create_game_events_and_log_entries # *1

      # byebug
      if events_boolean
        create_records_from_shifts()
        process_special_events()
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
      @team.rosters
      .map do |rstr|
        rstr.units end[0]
      .map do |unit|
        tally = unit.build_tally
        tally.tally_unit
        Hash[
          unit_id: unit.id,
          assists: tally.assists,
          plus_minus: tally.plus_minus,
          goals: tally.goals,
          points: tally.points,
          created_at: Time.now,
          updated_at: Time.now ]
      end
      byebug if prepared_tallies.blank?
      SQLOperations.sql_insert_all("tallies", prepared_tallies)
    end #create_tallies
  end #TeamSeason


  # ////////////// helpers /////////////// #
  private

  def get_schedule_dates(schedule_hash)
    schedule_hash["dates"].
    reject do |date|
      # "1" means preseason
      date["games"].first["gamePk"].to_s.
      slice(5) == "1" end
  end

  # def select_team_hash (teams_hash, team_id = nil)
  #   team_id ||= @team.team_id
  #
  #   teams_hash.select { |side|
  #     teams_hash[side]["team"]["id"] == team_id
  #   }.first[1]
  # end

  # add method #game_exists_query
  # games = @team.games.load unless @team.games.loaded?
  # if games.find do |game|
  #   game.game_id == game_id end
  # then return end

  module_function :create_teams_seasons, :create_teams_for_season
end


# *1 -
#  (improvement) store record of games processed, to track events already inserted. also [to conceivably allow for mutation of (external) API game data] track the results of ProcessSpecialEvents per game

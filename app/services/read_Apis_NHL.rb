# reload!; include ReadApisNHL; ReadApisNHL.create_teams_seasons

module ReadApisNHL


  #  create class/ Adapter for each team, to enable processing games only once per team (@processed_games)
    # -- can then replace NHLGameEventsAPI gate
$season = 20182019

include NHLTeamAPI
  def create_teams_seasons
    set_season($season)

    teams = Team.all
    # Team.left_outer_joins(rosters: [:units])
    # .where(season: @season)
    # .group("teams.id").having("COUNT(units.id) = 0")

    if teams.empty?
      # teams to which to associate opposing team rosters, per game
      create_all_teams_by_season()
    end

    teams.
    each do |team|
      @team_season =
      TeamSeason.new(season: @season, team: team)
      @team_season.create_records_from_APIs
      @team_season.create_tallies
      byebug
    end
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
      get_schedule_dates(schedule_hash)
      .select do |date|
        date["date"] < (Time.now - 85000) end

      schedule_dates[ get_next_date_index(schedule_dates)..-1]
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
        units_groups_hash = create_records_from_shifts()
        create_units_and_instances(units_groups_hash)

        process_special_events()
      end
    end #create_game_records

            # option: create the main roster
            # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster
    def create_rosters(game, teams_hash)
      teams_data =
      teams_hash
      .map do |side, side_hash|
        [ side_hash["team"]["id"],
          side_hash ] end
      .sort do |a,b|
        a.first <=> b.first end

      team_records =
      Team.where(team_id: teams_data.transpose.first).order(team_id: :ASC)

      teams_data
      .map.with_index do |array, i|
        CreateRoster::create_game_roster(
          array.second, team_records[i], game ) end
    end

    def create_tallies
      prepared_tallies =
      Unit.joins(:rosters)
      .where(rosters: {team_id: @team.id})
      .group(:id)
      .preload(:instances)
      .map do |unit|
        tally = unit.tallies.build
        tally.tally_instances
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
    schedule_hash["dates"]
    .reject do |date|
      # "1" means preseason
      date["games"].first["gamePk"].to_s.
      slice(5) == "1" end
  end

  def get_next_date_index (schedule_dates)
    max_game_id = Game.maximum(:game_id)
    last_game =

    schedule_dates
    .find do |date|
      date["games"].first["gamePK"] ==
      max_game_id end

    if last_game
      schedule_dates
      .index(last_game) + 1
    else
      0 end
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

  module_function :create_teams_seasons
end


# *1 -
#  (improvement) store record of games processed, to track events already inserted. also [to conceivably allow for mutation of (external) API game data] track the results of ProcessSpecialEvents per game

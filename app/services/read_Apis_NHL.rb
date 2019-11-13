# reload!; include ReadApisNHL; ReadApisNHL.create_teams_seasons
# ts = TeamSeason.new(season: 20182019, team: Team.first); ts.create_tallies;

module ReadApisNHL

$season = 20182019

include NHLTeamAPI
  def create_teams_seasons(i = 0, n = -1)
    set_season($season)

    teams = Team.all

    if teams.empty?
      # teams to which to associate opposing team rosters, per game
      create_all_teams_by_season()
    end

    # create records for transpired schedules
    teams[i..n]
    .each do |team|
      @team_season =
      TeamSeason.new(season: @season, team: team)
      @team_season.create_records_from_transpired_schedule
        # method that queries API vs database (?)
        # - latest game including team events...
      @team_season.create_tallies # if updates, update tallies
      # updates: new games; or events, in case of live updating
    end

    # set workers for live-update during coming schedule dates
    teams[i..n]
    .each do |team|
      @team_season =
      TeamSeason.new(season: @season, team: team)
      @team_season.set_workers_for_coming_schedule
      # @team_season.create_tallies # if updates, update tallies
      # updates: new games; or events, in case of live updating
    end

  end

  class TeamSeason

    def initialize (season:, team:)
      @season, @team = season, team
      @schedule_dates = set_schedule_dates()

      @start_time = nil; @end_time = nil; # store these in redis in case of server fail?
    end

    def set_schedule_dates
      # create team and get its schedule
      team_adapter =
      NHLTeamAPI::Adapter.new(team: @team)
      .find_or_create_team

      team_adapter.fetch_data
      @schedule_dates = get_schedule_dates(schedule_hash)
    end

    # two creation methods: one for transpired games and one to schedule worker for games to come
  include ReadApisNHL
  include Utilities

    def create_records_from_transpired_schedule
      transpired_schedule_dates =
      schedule_dates
      .select do |date|
        game_date = date["games"]["gameDate"]
        game_date_transpired? =
        Time.now.utc() - 86400 > # one day, in seconds
        Time.utc(
          *date_string_to_array(game_date)) # a lead time exists for populating game data
        # *2- zulu time, date hash format
      end

      transpired_schedule_dates[ get_next_date_index(transpired_schedule_dates)..-1]
      .each do |date_hash|
        create_records_per_game(date_hash) # sets @game for:
        create_game() end
    end #create_records_from_transpired_schedule

    def set_workers_for_coming_schedule
      coming_schedule_dates =
      @schedule_dates
      .select do |date|
        game_date = date["games"]["gameDate"]
        game_date_coming? =
        Time.now.utc() <
        Time.utc(
          *date_string_to_array(game_date)) end

      # set worker to get schedule dates for the next 3 days, every...3 days
      schedule_game_scheduler_jobs(coming_schedule_dates)  # can this accommodate recently completed and NHL-API-processed games?

        # - call #create_records_per_game, at start of each scheduled game
        # - then segment the game events creation methods, such that a worker scheduled after #create_records_per_game, may call these methods for each batch of events data
    end #set_workers_for_coming_schedule

  include CreateUnitsAndInstances
  include ProcessSpecialEvents
    def create_records_per_game(date_hash)
    # create a game for each schedule date
      game_id =
      date_hash["games"].first["gamePk"]

      @game, teams_hash =
      NHLGameAPI::Adapter
      .new(game_id: game_id)
      .create_game
      # game API may deliver two teams' players

      rosters = create_rosters(@game, teams_hash)
      @roster =
      rosters.find do |roster|
        roster.team.eql?(@team) end

    end #create_records_per_game

    def create_events
      inserted_events_array =
      NHLGameEventsAPI::Adapter
      .new(team: @team, game: @game )
      .create_game_events_and_log_entries # *1

      # byebug
      if inserted_events_array
        units_groups_hash = create_records_from_shifts(inserted_events_array)
        create_units_and_instances(units_groups_hash)

        process_special_events()
      end
    end

            # option: create the main roster
            # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster
    def create_rosters(game, teams_hash) #library method?
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
      .preload(:tallies)
      .map do |unit|
        if unit.tallies.empty?
          tally = unit.tallies.build
          tally.tally_instances
          Hash[
            unit_id: unit.id,
            assists: tally.assists,
            plus_minus: tally.plus_minus,
            goals: tally.goals,
            points: tally.points,
            '"TOI"': tally.TOI,
            created_at: Time.now,
            updated_at: Time.now
            # season: @teamseason.season
          ] end # if
      end.compact #map
      unless prepared_tallies.empty?
        SQLOperations.sql_insert_all("tallies", prepared_tallies)
      end
    end #create_tallies

    def schedule_game_scheduler_jobs(coming_schedule_dates, ts_instance)
      Sidekiq.set_schedule('schedule_live_data',
        { 'cron' => '0 0 2 */3 * *', 'class' => 'ScheduleLiveData',
          'args' => { coming_schedule_dates: coming_schedule_dates, instance: ts_instance }
          })
    end

    def schedule_live_data_init(date_hash, ts_instance)
      Sidekiq.set_schedule('schedule_live_data',
        { 'at' => date_hash["games"]["gameDate"], 'class' => 'LiveDataInit',
          'args' => { instance: ts_instance, date_hash: date_hash }
          })
    end

    def schedule_live_data_job(game_start_time, ts_instance)

      Sidekiq.set_schedule('live_data',
        { 'every' => ['2m'], 'class' => 'LiveData',
          'args' => { game_start_time: game_start_time, instance: ts_instance }
          })
    end

    private_class_method :set_live_data_worker_schedule
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

include ComposedQueries
  def get_next_date_index (schedule_dates)
        # find a game date which matches latest game record possible (order by game_id?)

# game processing LOGIC
    # find the last complete game [for season], if any
    # - find one with shift events
      # - unless this game corresponds to the last game record, use the subsequent game as starting index
      # - else, run live-game check for shift-completion

    query = games_by_team_shifts(:game_id, @team.id)
    games = ApplicationRecord.connection.execute(query.to_sql)
    max_game_id_hash = games
    .max_by do |game| game["game_id"] end
    max_game_id =
    max_game_id_hash["game_id"] if max_game_id_hash

    latest_game_record =
    schedule_dates
    .find do |date|
      date["games"].first["gamePk"] ==
      max_game_id end

    if latest_game_record
      schedule_dates
      .index(latest_game_record) + 1
    else
      0 end
  end

  def live_game_data_url (game_id, start_time)
    url = "https://statsapi.web.nhl.com/api/v1/game/#{game_id}/feed/live/diffPatch?startTimecode=#{start_time}" # startTimecode=yyyymmdd_hhmmss

  end


  def get_game_data
    JSON.parse(RestClient.get(TEAM_URL+"#{@team.team_id}"))
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

=begin

# *1 -
#  (improvement) store record of games processed, to track events already inserted. also [to conceivably allow for mutation of (external) API game data] track the results of ProcessSpecialEvents per game

*2 - zulu time
  zulu time = 4 hrs ahead of EST
  https://statsapi.web.nhl.com/api/v1/schedule?teamId=12&startDate=2018-09-01&endDate=2019-07-01
    (same lvl as "date")--
    "games" : [{ "gameDate" : "2019-04-24T23:30:00Z",

=end

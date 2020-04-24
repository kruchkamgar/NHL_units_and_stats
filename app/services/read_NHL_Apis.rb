# reload!; include ReadNHLApis; ReadNHLApiss.create_teams_seasons
# ts = TeamSeason.new(season: 20182019, team: Team.first); ts.create_tallies;
require 'sidekiq'
require 'sidekiq-scheduler'

module ReadNHLApis

$season = 20192020

include NHLTeamApi
  def create_teams_seasons(i = 0, n = -1)
    set_season($season)

    teams = Team.all

    if teams.empty?
      # teams to which to associate opposing team rosters, per game
      teams = create_all_teams_by_season()
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
      @team_season.set_workers_for_coming_schedule()
      # @team_season.create_tallies # if updates, update tallies
      # updates: new games; or events, in case of live updating
    end

  end

  class TeamSeason

    def initialize (season:, team:)
      @season, @team = season, team
      @schedule_dates = set_schedule_dates()
    end

    def game; @game end

    def set_schedule_dates
      # create team and get its schedule
      team_adapter =
      NHLTeamApi::Adapter.new(team: @team)
      .find_or_create_team

      schedule_hash = team_adapter.fetch_data
      @schedule_dates = get_schedule_dates(schedule_hash)
    end

    # two creation methods: one for transpired games and one to schedule worker/job for games to come
  include CreateRecordsFromApi
  include Utilities
  include ReadNHLApis

    def create_records_from_transpired_schedule
      transpired_schedule_dates =
      schedule_dates
      .select do |date|
        game_date = date["games"]["gameDate"]
        game_date_transpired =
        Time.now.utc() - 86400 > # one day, in seconds
        Time.utc(
          *date_string_to_array(game_date)) # a lead time exists for populating game data
        # *2- zulu time, date hash format
      end

      transpired_schedule_dates[ get_next_date_index(transpired_schedule_dates)..-1]
      .each do |date_hash|
        roster, game =
        create_initial_game_records(
          date_hash, team: @team) # sets @game for:
        create_records_derived_from_events(
          roster: roster[:roster], team: @team, game: game) end
    end #create_records_from_transpired_schedule

    def set_workers_for_coming_schedule
      coming_schedule_dates =
      @schedule_dates
      .select do |date|
        game_date = date["games"].first["gameDate"]
        game_date_coming =
        Time.now.utc() <
        Time.utc(
          *date_string_to_array(game_date)) end

      instance = self.attributes; instance.delete("schedule_dates");
      # set worker to get schedule dates for the next 3 days, every...3 days
        # worker then schedules other workers to handle each date
      schedule_game_scheduler_jobs(coming_schedule_dates, instance)
    end #set_workers_for_coming_schedule

    def schedule_game_scheduler_jobs(coming_schedule_dates, ts_instance)
      # 'cron' => '0 0 2 */3 0 0'
      Sidekiq.set_schedule('schedule_live_data',
        { 'every' => ['1h', first_in: '0s'], 'class' => 'ScheduleLiveData', 'queue' => 'schedule_live_data',
          'args' => { coming_schedule_dates: coming_schedule_dates, instance: ts_instance }
          })
    end

    class << self
      def schedule_live_data_init(date_hash, ts_instance)
        date = date_hash["games"].first["gameDate"]
        byebug
        Sidekiq.set_schedule("init_live_data_#{date}",
          { 'at' => "#{DateTime.now + 5}", 'class' => 'LiveDataInit', 'queue' => 'live_data',
            'args' => { date_hash: date_hash, instance: ts_instance }
            })
      end

      def schedule_live_data_job(start_time, ts_instance)
        Sidekiq.set_schedule('live_data',
          { 'every' => ['10s'], 'class' => 'LiveData',
            'args' => [ start_time, ts_instance ]
            })
      end
    end

    # private_class_method :schedule_game_scheduler_jobs

  end #TeamSeason


  # ////////////// helpers /////////////// #
  private

  def get_schedule_dates(schedule_hash)
    schedule_hash["dates"]
    .reject do |date|
      # "1" means preseason
      date["games"].first["gamePk"].to_s
      .slice(5) == "1" end
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

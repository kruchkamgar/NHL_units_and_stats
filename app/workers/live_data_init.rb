
require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)
    byebug
    team_roster, game, opponent_roster = CreateRecordsFromAPI::create_initial_game_records(
      date_hash, ts_instance["team"] ) # sets @game, including its game_id

    home_roster =
    [ team_roster, opponent_roster ]
    .find do |roster| roster[:side] == "home" end # could just determine home side via the game.home_side field, and match to roster.team.name

    away_roster = [ team_roster, opponent_roster ] - home_roster

    # cache the rosters

    # check cache keys [by game_id and initial time_stamp] to see if game already scheduled for another team
    scheduled = Rails.cache.read(
      game_id: instance[:game_id],
      # time_stamp: nil,
    ) #time_stamp: yyyymmdd_hhmmss

    unless scheduled
      url = ReadNHLApis::live_game_data_url("", "" )
      start_patch = fetch(url)

      LiveData.time_stamps

      # Rails.cache.write(
        # { game_id: instance[:game_id],
        #   time_stamp: start_time},
        # { time_stamps: [],
          # period_time: "00:00",
          # period: 1,
          # on_ice_plus:
          # { home: Array.new(6) do Hash[duration: 0] end,
          #   away: Array.new(6) do Hash[duration: 0] end },
          # home_roster: home_roster[:roster],
        #   away_roster: away_roster[:roster] }
      # ) # cache the initial time_stamp--(game start time)
      ReadNHLApis::schedule_live_data_job(
        ts_instance)
    end

  end

end


# set initial time_stamp
# LiveData.time_stamps[game_id.to_s] = [*ts_instance[:time_stamp]]

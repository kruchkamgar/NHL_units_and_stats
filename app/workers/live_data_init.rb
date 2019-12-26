
require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)
    byebug
    team_roster, game, opponent_roster = CreateRecordsFromAPI::create_initial_game_records(
      date_hash, ts_instance["team"] ) # sets @game, including its game_id

    # cache the rosters

    # check cache keys [by game_id and initial time_stamp] to see if game already scheduled for another team
    scheduled = Rails.cache.read(
      game_id: instance[:game_id],
      # time_stamp: nil,
    ) #time_stamp: yyyymmdd_hhmmss

    unless scheduled
      LiveData.time_stamps

      # Rails.cache.write(
        # { game_id: instance[:game_id],
        #   time_stamp: start_time},
        # { time_stamps: [start_time],
          # on_ice_plus:
          # { home: Array.new(6) do Hash[duration: 0] end,
          #   away: Array.new(6) do Hash[duration: 0] end },
          # home_roster: nil,
        #   away_roster: nil }
      # ) # cache the initial time_stamp--(game start time)
      ReadNHLApis::schedule_live_data_job(
        ts_instance)
    end

  end

end


# set initial time_stamp
# LiveData.time_stamps[game_id.to_s] = [*ts_instance[:time_stamp]]

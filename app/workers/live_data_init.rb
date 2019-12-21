
require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)
    byebug
    team_roster, game, opponent_roster = CreateRecordsFromAPI::create_initial_game_records(
      date_hash, ts_instance["team"] ) # sets @game, including its game_id
    # add the roster ids to ts_instance

    # check cache keys [by game_id and initial time_stamp] to see if game already scheduled for another team
    scheduled = Rails.cache.read(
      game_id: instance[:game_id],
      time_stamp: nil,
      home: nil,
      away: nil
    ) #time_stamp: yyyymmdd_hhmmss

    unless scheduled
      ts_instance.merge(time_stamps: [])
      ReadNHLApis::schedule_live_data_job( ts_instance )
    end

  end

end


# set initial time_stamp
# LiveData.time_stamps[game_id.to_s] = [*ts_instance[:time_stamp]]

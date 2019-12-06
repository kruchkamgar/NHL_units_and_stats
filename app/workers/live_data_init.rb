
require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)
    byebug
    team_roster, game, opponent_roster = CreateRecordsFromAPI::create_initial_game_records(
      date_hash, ts_instance["team"] ) # sets @game, including its game_id
    # add the roster ids to ts_instance

    LiveData.time_stamp = ts_instance[:time_stamp]
    # check redis keys [by game_id] to see if game already scheduled for another team
    ReadNHLApis::schedule_live_data_job( ts_instance ) unless scheduled

  end

end

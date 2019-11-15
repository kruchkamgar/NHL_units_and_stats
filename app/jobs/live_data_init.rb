
require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)
    byebug
    CreateRecordsFromAPI::create_initial_game_records( date_hash ) # sets @game, including its game_id
    ReadNHLApis::schedule_live_data_job( ts_instance )
  end

end


require 'sidekiq-scheduler'

class LiveDataInit
  include Sidekiq::Worker

  def perform(date_hash, ts_instance)

    byebug

    ts_instance.create_records_per_game(  ) # sets @game, including its game_id
    ReadApisNHL::schedule_live_data_job( args[:instance] )
  end

end

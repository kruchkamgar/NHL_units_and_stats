
class LiveDataInit
  queue_as :live_data

  def perform(args)

    args[:instance].create_records_per_game( args[:date_hash])
    ReadApisNHL::schedule_live_data_job( args[:instance] )
  end

end


class LiveData
  queue_as :live_data

  def perform(args)

    inst = args[:instance]
    inst.start_time = inst.end_time
    inst.end_time = Time.now.utc() + 3600
    # inst.end_time =
    # Utilities::TimeOperation.new(:+, inst.start_time, minutes: 2)

    url = ReadApisNHL::live_game_data_url(inst.start_time)
    live_data = fetch(url)
    args[:instance]
    .create_game_events_and_log_entries(live_data)
  end

end

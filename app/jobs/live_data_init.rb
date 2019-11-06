
class LiveDataInit
  queue_as :live_data

  def perform(ts_instance)

    # live_data = fetch(url_and_instance.first)
    ts_instance.create_events()
    ReadApisNHL::schedule_live_data_job(ts_instance)
  end

end

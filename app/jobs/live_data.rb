
class LiveData
  queue_as :live_data

  def perform(*url_and_instance)

    live_data = fetch(url_and_instance.first)
    url_and_instance.second
    .create_game_events_and_log_entries(live_data)
  end

end


require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker

  def perform(game_start_time, ts_instance)

    inst = ts_instance
    inst["start_time"] = inst["end_time"]
    inst.end_time = Time.now.utc() + 3600
    # inst.end_time =
    # Utilities::TimeOperation.new(:+, inst.start_time, minutes: 2)

    byebug
    url =
    ReadApisNHL::TeamSeason.live_game_data_url(inst.game.game_id, inst.start_time)
    live_data = fetch(url)
    args[:instance]
    .create_game_events_and_log_entries(live_data)
  end

end

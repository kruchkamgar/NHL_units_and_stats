
require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker

  def perform(game_start_time, ts_instance)
    # do this until game data says game has ended
      # - change the cron setting:
        # Sidekiq.set_schedule('live_data',
        #   { 'cron' => '* * * * * *', 'class' => 'LiveData',
        #     'args' => [ nil, nil ]
        #     })

    inst = ts_instance
    inst["start_time"] = inst["end_time"]
    inst["end_time"] = Time.now.utc() + 3600
    # inst.end_time =
    # Utilities::TimeOperation.new(:+, inst.start_time, minutes: 2)
    byebug

    url =
    ReadNHLApis::TeamSeason.live_game_data_url(
      inst["game"]["game_id"], inst["start_time"] )
    live_data = fetch(url)

    # cache game_instances
  end

end


# live-update: (NHL API does NOT offer live shift data)
  # find hypothetical sort index of earliest new event
  # find the earliest instance whose end time falls after this earliest event's start time (if any)
  # reset the queue with events populated from this earliest instance onward
  # remove the instances from this earliest instance onward

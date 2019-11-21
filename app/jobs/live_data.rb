
require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker

  # use sidekiq-scheduler for idempotence?
  def perform(start_time = nil, ts_instance)

    # check for game state -- finished?

    inst = ts_instance
    # inst["start_time"] = diff_patch["timeStamp"] # API offers current timeStamp
    diff_patch = fetch_diff_patch(
      inst["game"]["game_id"], inst["start_time"] )

    # while loop to find the next 'working' diffPatch time_stamp

    count_seconds = 0
    while diff_patch.empty? && count_seconds <= 7

      Thread.new do sleep 1; exit(0) end # or just call a new instance of this job?
      inst["start_time"] =
      Utilities::TimeOperation.new(:+, inst["start_time"], seconds: 1)

      diff_patch = fetch_diff_patch(
        inst["game"]["game_id"], inst["start_time"] )

      count_seconds += 1
    end

    # calculate the time difference

    # shift time of replaced player:
    # subtract the shift duration of the replacement player from the time difference


    # create new event data [after inst["start_time"]]

    # send event data through the process_special_events' case/when statements to tally

    # LiveData.perform_in(5.seconds, inst["start_time"])  # problems with idempotence
  end

private

  def fetch_diff_patch(game_id, time_stamp)
    url =
    ReadNHLApis::live_game_data_url(
      game_id, time_stamp )
    diff_patch = fetch(url)
  end

end

# "intermissionInfo" : {
#     "intermissionTimeRemaining" : 848,
#     "intermissionTimeElapsed" : 232,
#     "inIntermission" : true
#   },

# do this until game data says game has ended
  # - change the cron setting (delete not possible, currently):
    # Sidekiq.set_schedule('live_data',
    #   { 'cron' => '* * * * * *', 'class' => 'LiveData',
    #     'args' => [ nil, nil ]
    #     })

# live-update: (NHL API does NOT offer live shift data)
  # find hypothetical sort index of earliest new event
  # find the earliest instance whose end time falls after this earliest event's start time (if any)
  # reset the queue with events populated from this earliest instance onward
  # remove the instances from this earliest instance onward

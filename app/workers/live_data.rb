
require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker

  # use sidekiq-scheduler for idempotence?
  def perform(instance)

    # check for game state -- finished?
    inst = LiveDataState.new(instance)
    inst.cache_element

    diff_patch = fetch_diff_patch(
      inst.game_id, inst.time_stamp )
      # inst["game"]["game_id"], inst["time_stamp"] )

    # diff_patch: while loop to find the next 'working' diffPatch JSON timeStamp
    count_seconds = 0
    while diff_patch.empty? && count_seconds <= 7

      Thread.new do sleep 1; exit(0) end # or just call a new instance of this job?
      inst.time_stamp =
      Utilities::TimeOperation.new(:+, inst.time_stamp, seconds: 1)

      # begin rescue end?
      diff_patch = fetch_diff_patch(
        inst.game_id, inst.time_stamp )

      count_seconds += 1
    end # while

  # capture plays:
    # :result[:eventTypeId]
    diff_patch
    .each do |diff_hash|
      inst.plays
      .push(
        # use :path keys to capture plays
        diff_hash[:diff]
        .select do |patch|
          /allPlays/.match(patch[:path]) end
      )

      # ... and to capture on ice players (shifts)
      inst.onIce
      .push(
        diff_hash[:diff]
        .select do |patch|
          /onIce/.match(patch[:path]) ||
          /onIcePlus/.match(patch[:path])
        end
      )
    end

    byebug

    # :players.first[:playerType],
    # :players.first[:player][:fullName],
    # :players.first[:player][:id], # player_id_num
    # :about[:periodTime=>"16:16"],
    # :team

    Hash[
      "event_type": diff_patch[:result][:eventTypeId],
      # "coordinates": ...,
      player_id_num: diff_patch[:players].first[:player][:id], ] # player_id_num


  # capture shifts:
    # if :op => "remove" for /onIce/<integer>
      # shift change happened
    # else
      # shift continues: update happened
    # end

    byebug
    # calculate the time difference
    # diff_patch["timeStamp"]

    # {:op=>"replace",
      # :path=>"/liveData/boxscore/teams/away/onIcePlus/4/shiftDuration",
      # :value=>11},

    # shift time of replaced player:
    # subtract the shift duration of the replacement player from the time difference


    # create new event data [after inst["time_stamp"]]


    # send event data through the process_special_events' case/when statements to tally
      # - load rosters for the game from cache
      # - once per roster in game

    # {:op=>"replace", :path=>"/metaData/timeStamp", :value=>"20191117_052923"}
    inst.time_stamp = diff_patch.first[:diff].first[:value] # last array always holds timeStamp in first hash?

    # if a 'replace' exists for an event prior to the time_stamp, must change / update db

    inst.cache_element

    # LiveData.perform_in(5.seconds, inst["time_stamp"])  # (nix) problems with idempotence
  end # perform

# data model –
  # use an event's time_stamp for ID, until evident the API may correct / change these.
  # replacement of coordinates occurs - ex:
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

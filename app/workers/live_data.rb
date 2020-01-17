
require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker
  include Utilities

  mattr_writer :time_stamps
  # *1
  class << self
    def time_stamps; @@time_stamps ||= {} end
  end

  def perform(args)

    inst =
    Rails.cache.read(
      game_id: args[:game_id],
      time_stamp: @@time_stamps[args[:game_id]]
    )

puts "\ncheck inst for game_id? shouldnt exist\n\n"; byebug

    diff_patch = fetch_diff_patch(
      args[:game_id], inst[:time_stamps][-1] )
      # inst["game"]["game_id"], inst["time_stamp"] )

    # diff_patch: while loop to find the next 'working' diffPatch JSON timeStamp
    count_seconds = 0
    latest_time_stamp = inst[:time_stamps][-1]
    while diff_patch.empty? && count_seconds <= 7

      Thread.new do sleep 1; exit(0) end

      # increment the last couple digits by 1
      latest_time_stamp =
      Utilities::TimeOperation.new(:+,
        { format: 'yyyymmdd_hhmmss',
          time: latest_time_stamp },
        seconds: 1).original_format

      # begin rescue end?
      diff_patch = fetch_diff_patch(
        args[:game_id], latest_time_stamp )

      count_seconds += 1
    end # while

    # check for game state -- finished?
      # remove game_id key from @@time_stamps, if so

    # push new time stamp
    inst[:time_stamps] << diff_patch.first[:diff].first[:value] # does last array always holds timeStamp in first hash?
    @@time_stamps[args[:game_id]] = inst[:time_stamps][-1]

# track periodTime using STOP events to mark clock wind-down increments?
# - find "eventTypeId":"STOP"
# - find subsequent 'play'
# - find stoppages time [between time_stamps]
  # - subtract the former from the latter, and
  # - subtract sum from time stamp delta to find adjusted time
  # - compare time_stamp, with periodTime plus stoppages

# if multiple time_stamps per diff––
# - to appropriately calc stoppages, may process plays PER time_stamp
  # - a solution: group plays by time_stamp
  # - (also affects shiftDuration, )

    inst[:plays] = []
    diff_patch
    .each do |diff_hash|
      inst[:plays]
      .push(
        # use :path keys to capture plays
        diff_hash[:diff]
        .select do |patch|
          /allPlays/
          .match(patch[:path])
        end
      )
      inst[:plays] = inst[:plays].flatten(1)
      # ... and to capture on ice players (shifts)

      inst[:on_ice_diff] = []
      inst[:on_ice_diff]
      .push(
        diff_hash[:diff]
        .select do |patch|
          /onIce/.match(patch[:path])
        end
      )
      inst[:on_ice_diff] = inst[:on_ice_diff].flatten(1)
    end

    # byebug
  # //////// handle plays //////// #

    stoppages = []; stoppage_durations = []
    period_time = nil;

    events_and_log_entries_data = []
    inst[:plays]
    .each do |play|
      eventTypeId = play[:value][:result][:eventTypeId]
      periodTime = play[:value][:about][:periodTime]
      made_log_entries = nil

      # form log_entries, handle events' data
      case eventTypeId
      when "GOAL"
        log_entries_data =
        play[:value][:result][:players]
        .map do |player|
          case player[:playerType]
          when 'Scorer'
            action_type = "goal"
          when 'Assist'
            action_type = "assist"
          end

          Hash[
            player_id: player["player"]["id"],
            made_log_entry:
              Hash[
                action_type: action_type,
                created_at: Time.now,
                updated_at: Time.now ]]
        end
      when "MISSED_SHOT"
      when "SHOT"
      when "HIT"
      when "STOP", "FACEOFF", "PENALTY"
        if eventTypeId == "FACEOFF" then
          type = 'start'
          # form log_entries here
        end
        if eventTypeId == "STOP" || "PENALTY" then type = 'stop' end
        stoppages <<
          Hash[
            time: play[:value][:about][:dateTime],
            event: type ]
      when "PERIOD_END"
        period_end_time = play[:value][:about][:dateTime]
      when "PERIOD_START"
        period_end_time = play[:value][:about][:dateTime]
        inst[:period] = play[:value][:about][:period]
      end

      if stoppages.size.even?
        stoppage_durations <<
        # stoppage types happen in order; event: start|stop not needed
        TimeOperation.new(:-,
          [ { time: stoppages[-1][:time], format: "TZ" },
            { time: stoppages[-2][:time], format: "TZ" } ]).result end

      # merge each into log_entries hash
      events_and_log_entries_data <<
        Hash[
          event: Hash[
            game_id: inst[:game_id],
            event_type: eventTypeId,
            start_time: periodTime,
            period: inst[:period], # play[:value][:about][:period]
            # "coordinates": ...,
            player_id_num:
              play[:value][:players].first[:player][:id] ], # player_id_num
          log_entries: log_entries_data ]
    end

  # //////// derive and create shift events //////// #

    # match time_stamp to periodTime, by removing stoppage time
    if stoppage_durations.reduce(:+).nil? then stoppage_time = "0" end

    # hash: group home and away diffs respectively (onIce(Plus))
    diffs_grouped_side =
    inst[:on_ice_diff]
    .group_by do |patch|
      /(?<=teams\/)[a-zA-Z]+[^\/](?=\/onIce)/
      .match(patch[:path])[0]
    end
    # group onIce and onIcePlus respectively, within each of home and away diffs
    diffs_grouped_side_type =
    diffs_grouped_side
    .map do |key, value|
      Hash[ key =>
        value
        .group_by do |hash|
          /(?<=teams\/(?:away|home)\/)(onIce|onIcePlus)(?=[\/])/
          .match(hash[:path])[0] end ]
    end
  # byebug

  # capture shift events for each team/side
    diffs_grouped_side_type
    .each do |side_hash|
      side_hash
      .each do |side, diff_hash|
        _side = side.to_sym
        prior_player_events = [] # in case the shifts' diffs order out of sequence
        playerId_occurred = nil

        diff_hash['onIcePlus']
        .each do |diff|
          # puts "\n#{diff}\n"
          # capture shifts:
          replace = diff[:op] == "replace"
          add = diff[:op] == "add"
# replace_or_add = diff[:op] == "replace" || "add" || "remove"
            if replace ||
              add # ||
              # # problem: look for removals in 'onIce', rather
              # diffs_grouped_side[side]
              # .find do |_diff|
              #   _diff[:op] == "remove" &&
              #   /\/\d/.match(_diff[:path]) ==
              #   /\/\d/.match(diff[:path])
              # end # should find only within 'onIce'

              # if replace
                onIcePlus_id =
                /(?<=\/)\d/
                .match(diff[:path])[0].to_i

                replace_path =
                /(?<=onIcePlus\/\d\/)[a-zA-Z]+[^\"]/
                .match(diff[:path])
                add_path =
                Hash[
                  shiftDuration: value[:shiftDuration],
                  playerId: value[:playerId] ]

                # mutate game-state (inst[:on_ice_plus])——
                if replace_path
                   process_path(
                     replace_path[0], playerId_occurred, prior_player_events)
                else add_path
                  .each do |path|
                    process_path(
                      path.keys[0].to_s, playerId_occurred, prior_player_events) end
                end

              else
                # puts "\n\n'––remove; not replace––'\n\n"
                byebug
                # shift clearly over; can't do anything about it,
              end # if replace
            # "remove" occurs for "onIce"--
            else
            # shift continues: shift update happened in diff_patch
            end
        end # .each diff
      end # .each diff_hash
    end # .each side_hash

    events_and_log_entries_data
    .each do |data|
      make_events_and_log_entries(data) end

    # form instance from other players on ice concurrently in inst[:on_ice_plus]
    # - every time a player's shift ends, create an instance
      # - 1. next start_time becomes the previous instance's end_time,
        # - 1A. so long as no delay: the next start_time equals the previous instance end_time
        # - 1B else create a new [likely short] instance
      # - 2. upon 'remove' for onIcePlus, check for penalties, else wait for the next 'add' statement
    # - attach log entries to event and event to instance

    # byebug

    # create new event data [after inst["time_stamp"]]

    # send event data through the process_special_events' case/when statements to tally
      # - load rosters for the game from cache
      # - once per roster in game

    # {:op=>"replace", :path=>"/metaData/timeStamp", :value=>"20191117_052923"}

    #?-contingency: if a 'replace' exists for an event prior to the time_stamp, must change / update db

    Rails.cache.write({
      game_id: args[:game_id],
      time_stamp: inst[:time_stamp] },
      inst
    )

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

  def make_events_and_log_entries
    # create event if not created

    # make log entries
    NHLGameEventsAPI::Adapter.new().get_profile_by()
  end

  def process_path(path, playerId_occurred, prior_player_events)
    case path
    # API diff: shiftDuration updates alone, or w/ playerId also
    when 'playerId'
      # puts "\n'——player Id——'\n\n"
      playerId_occurred = true

      # remove prior_player_event from on_ice_plus
      prior_player_events[onIcePlus_id] =
      inst[:on_ice_plus][_side]
      .delete_at(onIcePlus_id)

      # add new player_event to inst[:on_ice_plus]
      inst[:on_ice_plus][_side]
      .insert( onIcePlus_id,
        Hash[ player_id_num: diff[:value], duration: 0 ] )

    # adjust time_stamp using stoppage_time
    when 'shiftDuration'
      # puts "\n\n'——shift duration——'\n\n"
      elapsed_duration = diff[:value]

      if playerId_occurred
        inst[:on_ice_plus][_side][onIcePlus_id][:start_time] =
        # on initial: should equate to game start time
        TimeOperation.new(:-,
          [ { format: 'yyyymmdd_hhmmss',
              time: inst[:time_stamps][-1] },
            stoppage_time,
            elapsed_duration ]
        ).result
        playerId_occurred = nil
      end

      if prior_player_events[onIcePlus_id]
        # puts "\n\n'––prior_player_event––'\n\n"
        # byebug
        # add from new player start_time back to previous time stamp

    #  verify: compare [a player's] evenTimeOnIce with calculated time between time stamps
    # - analytics sql query: sum durations for all shift events for the game and player

        prior_shift_duration_increment =
        TimeOperation.new(:-, [
          { format: 'yyyymmdd_hhmmss',
            time: inst[:time_stamps][-1] },
          elapsed_duration,
          # { format: "TZ",
          #   time: stoppage_time },
          stoppage_time,
          { format: 'yyyymmdd_hhmmss',
            time: inst[:time_stamps][-2] } ]
        ).result

        prior_player_events[onIcePlus_id][:duration] =
        TimeOperation.new(:+, [
          prior_shift_duration_increment,
          prior_player_events[onIcePlus_id][:duration] ]
        ).result

        prior_player_events[onIcePlus_id][:end_time] =
        TimeOperation.new(:+,
          [ prior_player_events[onIcePlus_id][:start_time],
            prior_player_events[onIcePlus_id][:duration] ])

        # create prior event [as it has finished]
        new_event =
        Event.find_or_create_by(
          prior_player_events[onIcePlus_id]
          .merge({
            event_type: 'shift',
            #start_Time: ,
            # end_time: ,
            shift_number: nil,
            period: inst[:period],
            game_id: args[:game_id],
            # player_id_num: ,
            created_at: Time.now,
            updated_at: Time.now
          }) )

        # either continuing shift, or initial

        prior_player_events[onIcePlus_id] = nil
      else
        inst[:on_ice_plus][_side][onIcePlus_id][:duration] += elapsed_duration

        puts "'––else––'\n\n"
        # byebug
      end
          # for latest info:
          #  update prior_player_event
    end # case onIcePlus...
  end #process_path

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

=begin (example GOAL play)

{"op":"add","path":"/liveData/plays/allPlays/282",
  "value":
    {
      "result": {
        "eventCode":"VAN588","secondaryType":"Snap Shot","eventTypeId":"GOAL",
        "strength":
          {"code":"EVEN","name":"Even"},
          "emptyNet":false,
          "description":"Brock Boeser (9) Snap Shot, assists: Elias Pettersson (17), Quinn Hughes (12)","event":"Goal"
      },
      "players":[
        {"seasonTotal":9,
        "playerType":"Scorer",
        "player":{
          "link":"/api/v1/people/8478444","fullName":"Brock Boeser","id":8478444}},
        {"seasonTotal":17,"playerType":"Assist","player":{"link":"/api/v1/people/8480012","fullName":"Elias Pettersson","id":8480012}},
        {"seasonTotal":12,"playerType":"Assist","player":{"link":"/api/v1/people/8480800","fullName":"Quinn Hughes","id":8480800}},
        {"playerType":"Goalie","player":{"link":"/api/v1/people/8477312","fullName":"Antoine Bibeau","id":8477312}
      }],
      "about": {
        "eventIdx":282,
        "dateTime":"2019-11-17T05:35:32Z",
        "eventId":588,
        "period":3,"periodType":"REGULAR","ordinalNum":"3rd","periodTime":"19:00","periodTimeRemaining":"01:00",
        "goals":{"away":4,"home":4}
      },
        "coordinates":{"x":-86,"y":-8},
        "team":{"name":"Vancouver Canucks","link":"/api/v1/teams/23","id":23,"triCode":"VAN"}
    }
}

=end

# live-update: (NHL API does NOT offer live shift data)

=begin
*1- idempotence
  use sidekiq-scheduler for idempotence? (over 'chained' workers)

=end

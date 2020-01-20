
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
    new_instance_data = {}
    # maintain queue of completed shift events [between time diffs?]
    queued_shifts = inst[:queued_shifts] # in case the shifts' diffs order out of sequence

    events_and_log_entries_data = []
    inst[:plays]
    .each do |play|
      eventTypeId = play[:value][:result][:eventTypeId]
      periodTime = play[:value][:about][:periodTime]
      made_log_entries = nil

      # form log_entries, handle events' data
      case eventTypeId
      when "GOAL"
        count_assisters = 1
        log_entries_data =
        play[:value][:result][:players]
        .map do |player|
          case player[:playerType]
          when 'Scorer'
            action_type = "goal"
          when 'Assist'
            if count_assisters == 1
              action_type = "primary"
            else action_type = "secondary" end
            count_assisters += 1
          end

          Hash[
            player_id_num: player["player"]["id"],
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

        if eventTypeId == "PENALTY" then new_instance_data[:penalty] = true end
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
        # new_player_bool = nil
        bools =
        Hash[
          :new_player_bool = nil
          :end_shift_bool = nil ]

        diff_hash['onIcePlus']
        .each do |diff|
          # puts "\n#{diff}\n"
          # capture shifts:
          case diff[:op]
          when "replace", "add", "remove" # || *2-

            onIcePlus_id =
            /(?<=\/)\d/
            .match(diff[:path])[0].to_i

            replace_path =
            /(?<=onIcePlus\/\d\/)[a-zA-Z]+[^\"]/
            .match(diff[:path]) if diff[:op] == 'replace'

            add_path =
            [
              Hash[
                key: 'playerId',
                value: diff[:value][:playerId] ]
              Hash[
                key: 'shiftDuration',
                value: diff[:value][:shiftDuration] ],
            ] if diff[:op] == 'add'

            # mutate game-state (inst[:on_ice_plus])——
            if replace_path
               process_path(
                 diff, replace_path[0], bools, queued_shifts, _side, onIcePlus_id)
            elsif add_path
              add_path
              .each do |path|
                process_path(
                  path, path[:key], bools, queued_shifts, _side, onIcePlus_id) end

            elsif new_instance_data[:penalties] && diff[:op] == "remove"
              penalty_for_matched_diff =
              inst[:plays]
              .find do |play|
                play[:value][:result][:players].first[:player][:id] ==
                inst[:on_ice_plus][_side][onIcePlus_id][:player_id_num]
              end #find

              if penalty_for_matched_diff
                process_path(
                  diff, diff[:op], nil, queued_shifts, _side, onIcePlus_id
                )

                bools[:end_shift_bool] = true
                process_path(
                  penalty_for_matched_diff, 'end_time', bools, queued_shifts, _side, onIcePlus_id
                )

            end # conditionals

          # shift continues: shift update happened in diff_patch
          end # case
        end # .each diff
      end # .each diff_hash
    end # .each side_hash

    created_events_and_made_log_entries =
    events_and_log_entries_data
    .map do |data|
      create_events_and_make_log_entries(data) end

  # trigger end of shift, on penalty + removal
    # set end_time shifts for players who took penalties
    if new_instance_data[:penalty]
      on_ice_plus =
      diffs_grouped_side_type
      .find do |side_hash| side_hash[side.to_sym]['onIcePlus'] end

        # if penalty
        # - find the side
        # - (can happen in .each diff flow):
          # - in the 'playerId' flow? (for new shift, rather than duration-update)
            # - find the related removal diff[:op] (by player_id_num)
            # - edit the queued_shifts
      inst[:plays]
      .each do |play|
        if play[:value][:result][:eventTypeId] == "PENALTY"

          # find the side
          team_name = play[:team][:name]
          _side =
          [ home_roster, away_roster ]
          .find do |roster|
            roster[:team] == team_name end
          .send(:[], :side).to_sym

          # for each penalty, find the onIcePlus player —removed— who took the penalty (the first player takes the penalty)
          player_id_num = play[:value][:result][:players].first[:player][:id]
          removal =
          on_ice_plus
          .find do |diff|
            onIcePlus_id = onIcePlus_id_(diff[:path])

            diff[:op] == "remove" &&
            player_id_num == inst[:on_ice_plus][_side][onIcePlus_id][:player_id_num]
          end

          queued_shifts[_side][onIcePlus_id] =
          inst[:on_ice_plus][_side]
          .delete_at(onIcePlus_id)
          # use penalty time to edit the end_time of player
          queued_shifts[_side][onIcePlus_id][:end_time] = play[:value][:about][:periodTime]
        end # if
      end # .each inst[:plays]
      # removals without penalty take the next adds [hopefully at a corresponding slot]
    end # if new_instance_data[:penalty]

    # form instance from other players on ice concurrently in inst[:on_ice_plus]

    # all listed events algo––
    # - find the next start or end time
      # - register all of them, and sort; combining duplicates
      # - create an instance for each one:
        # - either scan for all shifts [within queue] whose start_times happen before, and end_times after the marking time
        # - OR add all the next overlapping shifts (inclusive of start_time) to the queue
      # - remove shift, if an end time

    # event-driven algo––
    # - every time a player's shift ends OR a new player's shift starts after a penalty, create an instance
      # either 'diff[:op] == "add" or "replace" > 'playerId'
      # OR "remove" + penalty in 'plays'
      # > add means new player [after penalty?] or following a remove (delayed replace)
      # - 1. next start_time becomes the previous instance's end_time,

        # - 1A. so long as no delay: the next start_time equals the previous instance end_time
        # - 1B else create a new [likely short] instance

      # - 2. upon 'remove' for onIcePlus, check for penalties, else wait for the next 'add' statement
        # - use the penalty time to mark shift's end
        # - create instance
      # - 2alt. find penalties to mark the shift ends for 'remove' operations in diff
        # - find the indexed slot for the 'remove' operation [using penalty data?]

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

  def onIcePlus_id_(path)
    onIcePlus_id =
    /(?<=\/)\d/
    .match(path)[0].to_i end

  def fetch_diff_patch(game_id, time_stamp)
    url =
    ReadNHLApis::live_game_data_url(
      game_id, time_stamp )
    diff_patch = fetch(url)
  end

  def create_events_and_make_log_entries(data)
    event = Event.create(data[:event])
    Hash[
      event: event,
      # make log entries
      log_entries:
        data[:log_entries]
        .map do |entry_data|
          profile =
          NHLGameEventsAPI::Adapter.new(game: inst[:game_id])
          .get_profile_by(player_id_num: entry_data[:player_id_num])

          entry_data[:made_log_entry]
          .merge(
            event_id: event.id,
            profile_id: profile.id )
        end ]
  end

  def process_path(diff, path, bools, queued_shifts, _side, onIcePlus_id)
    # hash arguments?  _[:path], ... _[:onIcePlus_id]

    # API diff: 'shiftDuration' lists after 'playerId', but updates alone
    case path
    when 'playerId', 'remove'
      # puts "\n'——player Id——'\n\n"
      # remove queued_shift from on_ice_plus
      queued_shifts[onIcePlus_id] =
      inst[:on_ice_plus][_side]
      .delete_at(onIcePlus_id)

      # prepare for 'shiftDuration'
      if path == 'playerId'
        new_player_bool = true # return this
        # add new player_event to inst[:on_ice_plus]
        inst[:on_ice_plus][_side]
        .insert( onIcePlus_id,
          Hash[ player_id_num: diff[:value], duration: 0 ] )
      elsif
        path == 'remove' then end_shift_bool = true end

    when 'shiftDuration', 'end_time'
      # new_player_bool alternative: look up if playerId in diff
      # puts "\n\n'——shift duration——'\n\n"
      elapsed_duration = diff[:value]

      if bools[:new_player_bool] # new shift
        inst[:on_ice_plus][_side][onIcePlus_id][:start_time] =
        # on initial: should equate to game start time
        TimeOperation.new(:-,
          [ { format: 'yyyymmdd_hhmmss',
              time: inst[:time_stamps][-1] },
            stoppage_time,
            elapsed_duration ]
        ).result
        bools[:new_player_bool] = nil # return this
      else
        inst[:on_ice_plus][_side][onIcePlus_id][:duration] = elapsed_duration # assumes API durations update, rather than increment
      end

      # - calc duration and derive end_time;
      # - create shift event
      if bools[:new_player_bool] || path == 'end_time' &&
        !queued_shifts[onIcePlus_id].empty?
        # puts "\n\n'––queued_shift_event––'\n\n"; byebug

  #  verify: compare [a player's] evenTimeOnIce with calculated time between time stamps
  # - analytics sql query: sum durations for all shift events for the game and player

        if bools[:new_player_bool]
          # calc increment as: time_stamp minus new player elapsed shift duration
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

          # increment the duration
          queued_shifts[onIcePlus_id][:duration] =
          TimeOperation.new(:+, [
            prior_shift_duration_increment,
            queued_shifts[onIcePlus_id][:duration] ]
          ).result

          # calc end_time
          queued_shifts[onIcePlus_id][:end_time] =
          TimeOperation.new(:+,
            [ queued_shifts[onIcePlus_id][:start_time],
              queued_shifts[onIcePlus_id][:duration] ])

        elsif path == 'end_time'
          # set end time from penalty API data (diff)
          queued_shifts[onIcePlus_id][:end_time] =
          diff[:about][:periodTime]
        end

        # create event from queued shift [as it has finished]
        queued_shift_events <<
        new_event =
        Event.find_or_create_by(
          queued_shifts[onIcePlus_id]
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

        queued_shifts[onIcePlus_id] = nil; end_shift_bool = nil;
      else
        # set initial duration
        inst[:on_ice_plus][_side][onIcePlus_id][:duration] = elapsed_duration

        puts "'––else––'\n\n"
        # byebug
      end
          # for latest info:
          #  update queued_shift_event
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

=end

# live-update: (NHL API does NOT offer live shift data)

=begin
*1- idempotence
  use sidekiq-scheduler for idempotence? (over 'chained' workers)

*2- onIce vs onIcePlus
  # # problem: look for removals in 'onIce', rather
  # diffs_grouped_side[side]
  # .find do |_diff|
  #   _diff[:op] == "remove" &&
  #   /\/\d/.match(_diff[:path]) ==
  #   /\/\d/.match(diff[:path])
  # end # should find only within 'onIce'

=end

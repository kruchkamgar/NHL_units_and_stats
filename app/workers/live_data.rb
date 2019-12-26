
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
    # byebug

    diff_patch = fetch_diff_patch(
      args[:game_id], inst[:time_stamps][-1] )
      # inst["game"]["game_id"], inst["time_stamp"] )

    # diff_patch: while loop to find the next 'working' diffPatch JSON timeStamp
    count_seconds = 0
    latest_time_stamp = inst[:time_stamps][-1]
    while diff_patch.empty? && count_seconds <= 7

      Thread.new do sleep 1; exit(0) end # or just call a new instance of this job?

      # increment the last couple digits by 1
      latest_time_stamp =
      Utilities::TimeOperation.new(:+, latest_time_stamp, seconds: 1)

      # begin rescue end?
      diff_patch = fetch_diff_patch(
        inst[:game_id], inst[:time_stamps][-1] )

      count_seconds += 1
    end # while

    # check for game state -- finished?
      # remove game_id key from @@time_stamps, if so

    # push new time stamp
    inst[:time_stamps] << diff_patch.first[:diff].first[:value] # does last array always holds timeStamp in first hash?
    @@time_stamps[args[:game_id]] = inst[:time_stamps][-1]

    inst[:plays] = []
  # capture plays:
    # :result[:eventTypeId]
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

    # :players.first[:playerType],
    # :players.first[:player][:fullName],
    # :players.first[:player][:id], # player_id_num
    # :about[:periodTime=>"16:16"],
    # :team
    formed_events =
    inst[:plays]
    .map do |play|
      Hash[
        game_id: inst[:game_id],
        event_type:
          play[:value][:result][:eventTypeId],
        start_time: play[:value][:about][:periodTime],
        period: play[:value][:about][:period],
        # "coordinates": ...,
        player_id_num:
          play[:value][:players].first[:player][:id], ] # player_id_num
    end

    # make log entries

    # byebug

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

    # on_ice_plus_diff =
    # diff_hash[:diff]
    # .select do |patch|
    #   /onIcePlus/.match(patch[:path]) end
    # on_ice_diff =
    # diff_hash[:diff]
    # .select do |patch|
    #   /onIce/.match(patch[:path]) end
  # byebug

  # capture for each team/side
    diffs_grouped_side_type
    .each do |side_hash|
      side_hash
      .each do |side, diff_hash|
        _side = side.to_sym
        prior_player_events = [] # in case the shifts' diffs order out of sequence

        diff_hash['onIcePlus']
        .each do |diff|
          puts "\n#{diff}\n"
        # .each do |type, diffs|
          # diffs
          # capture shifts:
          replace = diff[:op] == "replace"
            if replace ||
              diffs_grouped_side[side]
              .find do |_diff|
                _diff[:op] == "remove" &&
                /\/\d/.match(_diff[:path]) ==
                /\/\d/.match(diff[:path])
              end # look for removals in onIce

              if replace
                onIcePlus_id =
                /(?<=\/)\d/
                .match(diff[:path])[0].to_i

                # mutate game-state (inst[:on_ice_plus])——
                case /(?<=onIcePlus\/\d\/)[a-zA-Z]+[^\"]/
                  .match(diff[:path])[0]
                # API diff will update either shiftDuration alone, or update it for an updated playerId
                when 'playerId'
                  puts "\n'——player Id——'\n\n"

                  # remove prior_player_event from on_ice_plus
                  prior_player_events[onIcePlus_id] =
                  inst[:on_ice_plus][_side]
                  .delete_at(onIcePlus_id)

                  # add new player_event to inst[:on_ice_plus]
                  inst[:on_ice_plus][_side]
                  .insert( onIcePlus_id,
                    Hash[ player_id_num: diff[:value], duration: 0 ] )

                  byebug
                when 'shiftDuration'
                  puts "\n\n'——shift duration——'\n\n"
                  elapsed_duration = diff[:value]

                      # if prior_player_event ||
                      # [if diff_patch incl. 2 time_stamps] find prior player event (another match)
                        # ppe_in_current_diff =

                  if prior_player_events[onIcePlus_id]
                    puts "\n\n'––prior_player_event––'\n\n"
                    byebug
                    # add from new player start_time back to previous time stamp
                    prior_player_event[:duration] +=
                    (inst[:time_stamps][-1] - elapsed_duration) - inst[:time_stamps][-2]

                        # create prior event
                        # either continuing shift, or initial

                    prior_player_events[onIcePlus_id] = nil
                  else
                    byebug unless inst[:on_ice_plus][_side][onIcePlus_id]

                    inst[:on_ice_plus][_side][onIcePlus_id][:duration] += elapsed_duration

                    inst[:on_ice_plus][_side][onIcePlus_id][:start_time] =
                    # on initial: should equate to game start time
                    TimeOperation.new(
                      :-,
                      { format: 'yyyymmdd_hhmmss',
                        time: inst[:time_stamps][-1] },
                      elapsed_duration ).result

                    puts "'––else––'\n\n"
                    byebug
                  end

                      # for latest info:
                       # update prior_player_event
                end

              else
                puts "\n\n'––not replace––'\n\n"
                byebug
                # shift clearly over; can't do anything about it,
                # until the replace shows the duration of the subsequent shift
              end # if replace

            # remove occurs for onIce--
            else
            # shift continues: shift update happened in diff_patch
            end
        end if side == "home" # .each diff
        # end # .each diffs
      end # .each diff_hash
    end # .each side_hash

    byebug

    # {:op=>"replace",
      # :path=>"/liveData/boxscore/teams/away/onIcePlus/4/shiftDuration",
      # :value=>11},

    # create new event data [after inst["time_stamp"]]

    # send event data through the process_special_events' case/when statements to tally
      # - load rosters for the game from cache
      # - once per roster in game

    # {:op=>"replace", :path=>"/metaData/timeStamp", :value=>"20191117_052923"}

    #?-contingency: if a 'replace' exists for an event prior to the time_stamp, must change / update db

    Rails.cache.write({
      game_id: args[:game_id],
      time_stamp: inst[:time_stamp] },
      # content...
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

=begin
*1- idempotence
  use sidekiq-scheduler for idempotence? (over 'chained' workers)

=end


require 'sidekiq-scheduler'

class LiveData
  include Sidekiq::Worker

  mattr_writer :time_stamps

  def time_stamps; @@time_stamps ||= {} end
  # use file for more resilience--
  # time_stamp_file = File.new(Rails.root / 'tmp' / "#{@game_id}" , "w" )

  # *1
  def perform(instance)
    # check for game state -- finished?
      # remove game_id key from @@time_stamps, if so
    inst = LiveDataState.new(
      instance.merge(time_stamp:
        @@time_stamps[@game_id][-1]) ) # or find the latest cached time_stamp
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

      inst.on_ice_diff
      .push(
        diff_hash[:diff]
        .select do |patch|
          /onIce/.match(patch[:path])
        end
      )
      # inst.on_ice[:on_icePlus]
      # .push(
      #   diff_hash[:diff]
      #   .select do |patch|
      #     /on_ice/.match(patch[:path]
      #   end
      # )
    end

    byebug

    # :players.first[:playerType],
    # :players.first[:player][:fullName],
    # :players.first[:player][:id], # player_id_num
    # :about[:periodTime=>"16:16"],
    # :team
    formed_events =
    inst.plays
    .map do |play|
      Hash[
        game_id: inst.game_id,
        event_type: play.first[:value][:result][:eventTypeId],
        start_time: play.first[:value][:about][:periodTime],
        period: play.first[:value][:about][:period],
        # "coordinates": ...,
        player_id_num: play.first[:value][:players].first[:player][:id], ] # player_id_num
    end

    # make log entries

    byebug

    # hash: group home and away diffs respectively (onIce(Plus))
    diffs_grouped_side =
    diff_hash[:diff]
    .group_by do |patch|
      /(?<=teams\/)[a-zA-Z]+[^\/](?=\/onIce)/
      .match(patch[:path]) end

    # group onIce and onIcePlus respectively, within each of home and away diffs
    diffs_grouped_side_type =
    diffs_grouped_side
    .map do |key, value|
      Hash[ key =>
        value
        .group_by do |hash|
          /(?<=teams\/(?:away|home)\/)(onIce|onIcePlus)(?=[\/])/
          .match(hash.values[0])[0] end ]
    end.to_h

    # on_ice_plus_diff =
    # diff_hash[:diff]
    # .select do |patch|
    #   /onIcePlus/.match(patch[:path]) end
    # on_ice_diff =
    # diff_hash[:diff]
    # .select do |patch|
    #   /onIce/.match(patch[:path]) end

  # capture for each team/side
    diffs_grouped_side_type
    .each do |side, types|
      types
      .each do |type, diffs|
        diffs
        .each do |diff|
      # capture shifts:
        replace = diff[:op] == "replace"
          if replace ||
            on_ice_diff
            .find do |_diff|
              /\/\d/.match(_diff[:path]) ==
              /\/\d/.match(diff[:path]) &&
              _diff[:op] == "remove"
            end

            if replace
              # check what type of diff update: stamina, shiftDuration, playerId, ...
              onIcePlus_id =
              /\/\d/
              .match(shift[:path])[0]

              case /(?<=onIcePlus\/\d\/)[a-zA-Z]+[^\"]/
                .match(diff[:path]).first
              # API diff will update either shiftDuration alone, or update it for an updated playerId
              when 'playerId'
                # prior_player_event = find prior player event via onIcePlus_id
                  # remove prior_player_event from on_ice_plus
                prior_player_event =
                inst.on_ice_plus[side]
                .delete_at(onIcePlus_id)

                # add new player_event to inst.on_ice_plus

              when 'shiftDuration'
                # if prior_player_event || find prior player event in diff_patch
                  # then add time_stamp - shiftDuration to prior_player shift duration
                # else
                /(?<=shiftDuration.{3})[^}0-9]+(\d{2,3})/
                .match(on_ice[:path])

                if prior_player_event
                  # time_stamp - @@time_stamps[@game_id] -
                  # create prior event
                else # do nothing
                end

                # for latest info:
                 # update prior_player_event
              end

              # concluding 'shift segment's duration, for replaced player:
                # subtract the shift duration of the replacement player from the time difference

              byebug
            else
              byebug
              # shift clearly over; can't do anything about it,
              # until the replace shows the duration of the subsequent shift
            end

            # "remove" for /on_ice/<integer>
              # case "remove"
              #   verify that shift change happened
              #     - find any matching "replace" statement for /<integer>
              # end
          else
            # shift continues: update happened
          end

        end # .each diff
      end # .each diffs
    end # .each side

    byebug
    # calculate the time difference
    @@time_stamps[@game_id] << diff_patch["timeStamp"]

    # {:op=>"replace",
      # :path=>"/liveData/boxscore/teams/away/onIcePlus/4/shiftDuration",
      # :value=>11},

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

=begin
*1- idempotence
  use sidekiq-scheduler for idempotence? (over 'chained' workers)

=end

=begin
Get the shifts events from API and call SynthesizeUnits functionality
-

make this a standalone or mixin-only module for gameAPI module?
=end


module NHLGameEventsAPI

  class Adapter

    SHIFT_CHARTS_URL = 'http://www.nhl.com/stats/rest/shiftcharts'

    def initialize (team:, game:, roster:)
      @team = team
      @game = Game.where(id: game).includes(:player_profiles)[0]
      @roster = Roster.where(id: roster).includes(:players)[0]
    end

    def create_game_events
      if Event.where(game_id: game.game_id) then return true end
        # grab and subtract from API events, if live-updating

      events = fetch_data(get_shifts_url)["data"]
      events_by_team = events.select { |event|
        event["teamId"] == @team.team_id
      }
      special_events = events_by_team.select { |event|
        event["eventDescription"]
      }
      shift_events_by_team = events_by_team - special_events

      new_events_array = shift_events_by_team.map do |event|

        Hash[
          event_type: event["eventDescription"] || "shift", #API lists null, except for goals
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id,
          created_at: Time.now,
          updated_at: Time.now
        ]
      end
      # insert events
      events_changes = SQLOperations.sql_insert_all("events", new_events_array )
      # grab events
      if events_changes > 0
        inserted_events = Event.where("game_id = '#{@game.id}'", "event_type = 'shift'") #*2
      end

      # map log entries for each event
        # (these players and profiles should already exist by now)
      new_log_entries_array = inserted_events.map do |event|
        records_hash = get_player_and_profile_by ({
            player_id_num: event.player_id_num
          })

        Hash[
          event_id: event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "shift",
          created_at: Time.now,
          updated_at: Time.now
        ] #*3
      end
      # insert events
      log_entries_changes = SQLOperations.sql_insert_all("events", new_events_array )
      # grab events
      if log_entries_changes > 0
        # inserted_events = Event.where("game_id: '#{@game.id}'", "event_type = 'shift'")
      end

      create_special_game_events special_events
      events.any?
    end #create_game_events

    private

    # create events; and then log entries for player_profiles involved in the event
    def create_special_game_events(special_events)
      goal_string = "goal"

      new_events_array = special_events.map do |event|
        Hash[
          event_type: event["eventDescription"],
          duration: event["duration"] || "null",
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id,
          created_at: Time.now,
          updated_at: Time.now
        ]
      end

      events_changes = SQLOperations.sql_insert_all("events", new_events_array )

      # just use value of Changes() and ORDER DESC LIMIT ...
      num_queries = new_events_array.map {
          "player_id_num = ? AND end_time = ?"
        }
      inserted_events = Event.find_by_sql ["
        SELECT * FROM events
        WHERE #{num_queries.join(' OR ')}", *new_events_array.map { |event|
          [event[:player_id_num], event[:end_time]]
        }.flatten ]
        #gets select events, based on their individual data for given fields

      new_log_entries_array = []
      # create associated log_entries for each created event
      special_events.each do |event|
        new_event = inserted_events.find { |i_evnt|
            i_evnt.end_time == event["endTime"]
          }
        # get roster player's game profile by matching to info from API data- 'event'
        records_hash = get_player_and_profile_by({
            player_id_num: event["playerId"]
          })
        new_scorer_log_entry = Hash[
          event_id: new_event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "goal",
          created_at: Time.now,
          updated_at: Time.now
        ]

        # get UP TO two full names separated by comma and space
        assisters= []
        event["eventDetails"].gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) { |m| assisters << $~ }
          byebug unless event["eventDetails"]
          # create a log entry per assister(s)
        new_assister_log_entries = assisters.map {
            |player|
            action_type = ''
            records_hash = get_player_and_profile_by ({
                first_name: player["first_name"],
                last_name: player["last_name"]
              })

              if assisters.find_index(player) == 0 then action_type = "primary" else action_type = "secondary" end

              Hash[
                event_id: new_event.id,
                player_profile_id: records_hash[:profile].id,
                action_type: action_type,
                created_at: Time.now,
                updated_at: Time.now
              ]
          }

        new_log_entries_array += [new_scorer_log_entry] + new_assister_log_entries
      end
      log_entries_changes = SQLOperations.sql_insert_all("log_entries", new_log_entries_array )

    end

    # get game's player_profile, of roster player (via  NHLRosterAPI.rb)
    # roster > players; game > player_profiles; player > player_profiles
    def get_player_and_profile_by (**search_hash)
      #cross-reference (inserted) event with roster player
      player = @roster.players.find { |player|
        search_hash.keys.map do |method|
          search_hash[method] == player.send(method)
        end.all?
      }
        byebug unless player
      # player_profile = @game.player_profiles.find_by(player_id: player.id)
      player_profile = @game.player_profiles.find {
        |profile|
          profile.player_id == player.id
        }
        byebug unless player_profile

      { profile: player_profile }
    end

    def get_shifts_url
      "#{SHIFT_CHARTS_URL}?cayenneExp=gameId=#{@game.game_id}"
    end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

  end #class Adapter
end


=begin
*1-
(nevermind, as API omits player positions per-shift) perhaps process the goal events, after synthesizing the units, to cross-reference the corresponding player profile matching the assist.
  .- check the time of the event against the players' shifts' times
    .=> player_profile.logs.select { |log| log.start_time < event.time < log.end_time }

*2-
Use the OUTPUT sql command, to output ids into a table using DECLARE ... TABLE
https://stackoverflow.com/questions/810962/getting-new-ids-after-insert.
=end

# could ALSO just grab the last X inserted records, per the Changes() sqlite function

# *3-
# NHL API currently omits the per-shift position of players
# could manually edit based on known line combinations (player 1 plays center when on unit alongside players 2, 3)

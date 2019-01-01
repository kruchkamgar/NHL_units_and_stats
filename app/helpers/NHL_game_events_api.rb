=begin
Get the shifts events from API and call SynthesizeUnits functionality
-
=end


module NHLGameEventsAPI

  class Adapter

    SHIFT_CHARTS_URL = 'http://www.nhl.com/stats/rest/shiftcharts'

    def initialize (team:, game:, roster:)
      @team = team
      @game = Game.where(id: game).includes(:player_profiles)[0]
      @roster = Roster.where(id: roster).includes(:players)[0]
    end

    def create_game_events_and_log_entries
byebug
      if Event.where(game_id: @game.id).any? then return true end
        # for 'add new events' functionality: grab events w/ game id, and subtract from API events (for ex: live-updating)

      events = fetch_data(get_shifts_url)["data"]
      events_by_team = events.select { |event|
        event["teamId"] == @team.team_id
      }
      goal_events = events_by_team.select { |event|
        event["typeCode"] == 505
      }
      shift_events_by_team = events_by_team - goal_events

      inserted_events = create_events (shift_events_by_team)
      create_log_entries (inserted_events)

      inserted_goal_events = create_goal_events goal_events
      create_goal_log_entries (goal_events, inserted_goal_events)
    end

    def create_events (shift_events_by_team)

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
    end

    # map log entries for each event
    # (these players and profiles should already exist by now)
    def create_log_entries ()
      new_log_entries_data = inserted_events.map do |event|
        records_hash = get_profile_by ({
            player_id_num: event.player_id_num
          })
          [event, records_hash]
        end

      new_log_entries_array = new_log_entries_data.map do |event, records_hash|
        Hash[
          event_id: event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "shift",
          created_at: Time.now,
          updated_at: Time.now
        ] #*3
      end
      # insert events
      log_entries_changes = SQLOperations.sql_insert_all("log_entries", new_log_entries_array )
      # grab events
      if log_entries_changes > 0
      end

      events.any?
    end #create_game_events


    # create events; and then log entries for player_profiles involved in the event
    def create_goal_events(goal_events)

      new_events_array = goal_events.map do |event|
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

      byebug
      events_changes = SQLOperations.sql_insert_all("events", new_events_array )

      # just use value of Changes() and ORDER DESC LIMIT ...
      num_queries = new_events_array.map {
          "player_id_num = ? AND end_time = ? AND (event_type = 'SHG' OR event_type = 'PPG' OR event_type = 'EVG')"
        }
      inserted_events = Event.find_by_sql ["
        SELECT * FROM events
        WHERE #{num_queries.join(' OR ')}", *new_events_array.map { |event|
          [event[:player_id_num], event[:end_time]]
        }.flatten ]
        #gets select events, based on their individual data for given fields

    end

    def create_goal_log_entries(goal_events, inserted_events)

      @api_events_with_created_events = goal_events.map do |api_event|
        created_event = inserted_events.find { |ins_evnt|
            ins_evnt.end_time == api_event["endTime"]
          }

          [api_event, created_event]
        end

      # aggregate prepared log_entries' hash arrays
      new_log_entries_array = get_new_scorer_log_entries + get_new_assisters_log_entries

      log_entries_changes = SQLOperations.sql_insert_all("log_entries", new_log_entries_array )
    end

    def get_new_scorers_log_entries
      # retrieve event and player_profile records
      new_scorers_data = @api_events_with_created_events.map do |api_event, created_evt|
          records_hash = get_profile_by({
              player_id_num: api_event["playerId"]
            })
          [created_evt, records_hash]
        end

      new_scorers_log_entries = new_scorers_data.map do |created_evt, records_hash|
          Hash[
            event_id: created_evt.id,
            player_profile_id: records_hash[:profile].id,
            action_type: "goal",
            created_at: Time.now,
            updated_at: Time.now
          ]
        end
    end

    def get_new_assisters_log_entries

      new_assisters_data = @api_events_with_created_events.map do |api_event, created_evt|
          next unless api_event["eventDetails"]
          assisters = []

          # get UP TO two full names separated by comma and space
          api_event["eventDetails"].gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) { |m|
             assisters << $~
           }

          # retrieve player profile records
          assisters_data = assisters.map do
              |player|
              if assisters.find_index(player) == 0
                action_type = "primary" else action_type = "secondary" end

              records_hash = get_profile_by ({
                  first_name: player["first_name"],
                  last_name: player["last_name"]
                })

              { records: records_hash, action_type: action_type }
            end

          [created_evt, assisters_data]
        end

      new_assisters_log_entries = new_assisters_data.map do |created_evt, assisters_data|
        assisters_data.map { |assister|
          Hash[
            event_id: created_evt.id,
            player_profile_id: assister[:records][:profile].id,
            action_type: assister[:action_type],
            created_at: Time.now,
            updated_at: Time.now
          ]
        }
      end

    end #get_new_assisters_log_entries

    # get game's player_profile, of roster player (via  NHLRosterAPI.rb)
    # roster > players; game > player_profiles; player > player_profiles
    def get_profile_by (**search_hash)
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

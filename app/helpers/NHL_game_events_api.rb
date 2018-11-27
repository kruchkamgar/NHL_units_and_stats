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
      @game = game.includes(:player_profiles)
      @roster = roster.includes(:players)
    end

    def create_game_events

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
          event_type: event["eventDescription"] ||= "shift", #API lists null, except for goals
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id
        ]
      end

      # insert events
      # grab events
      inserted_events = Event.where("game_id: '#{@game.id}'", "event_type = 'shift'") #*2
      # map log entries for each event
        # (these players and profiles should already exist by now)
        records_hash = get_player_and_profile_by ({
          :player_id => event["playerId"]
          })

        # NHL API currently omits the per-shift position of players
        # could manually edit based on known line combinations (player 1 plays center when on unit alongside players 2, 3)
        LogEntry.find_or_create_by(
          event_id: new_event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "shift"
        )
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
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id
        ]
      end

        # "VALUES (CSV string1),(string2),(string3)...
        insert_events = new_events_array.map {
            |event_hash| event_hash.values.join(',')
          }

        sql_events = "
        INSERT INTO events (#{new_events_array.first.keys.map(&:to_s).join(',')} )
        VALUES ( #{insert_events.join('),(')} )"

        begin
          ApplicationRecord.connection.execute(sql_events)
        rescue StandardError => e
          puts "\n\n error: \n\n #{e}"
        end
        # if updates to database occurred (inserts)
        if ApplicationRecord.connection.execute("SELECT Changes()").first["changes()"] == 1
        end

      num_queries = new_events_array.map {
          "player_id_num = ? AND end_time = ?"
        }
      inserted_events = Event.find_by_sql ["
        SELECT * FROM events
        WHERE #{num_queries.join(' OR ')}", new_events_array.map { |event|
          [event[:player_id_num], event[:end_time]]
        }.flatten ]

      # Event.where("game_id: '#{@game.id}'", "event_type != 'shift'") #*2

      # create associated log_entries for each created event
      special_events.each do |event|
        new_event = inserted_events.find_by( end_time: event["endTime"] )

        # get roster player's game profile by matching to info from API data- 'event'
        records_hash = get_player_and_profile_by({
          :player_id => event["playerId"]
          })
        new_scorer_log_entry = Hash[
          event_id: new_event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "goal"
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
                action_type: action_type
              ]
          }

        new_log_entries = [new_scorer_log_entry] + new_assister_log_entries

        created_log_entries = LogEntry.create(new_log_entries)
      end
    end

    def create_log_entry(event, records_hash, action_type)
      # LogEntry.find_or_create_by(
      #   event_id: event.id,
      #   player_profile_id: records_hash[:profile].id,
      #   action_type: action_type
      # )
    end

    # get the roster player and player_profile (created in NHLRosterAPI.rb), using the event's info via API data.
    # roster > players; game > player_profiles; player > player_profiles
    def get_player_and_profile_by (**search_hash)

      player = @roster.players.find_by (search_hash)
        byebug unless player
      player_profile = @game.player_profiles.find_by(player_id: player.id)
        byebug unless player_profile

      { player: player, profile: player_profile }
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

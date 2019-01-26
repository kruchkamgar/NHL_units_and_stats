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
      # if Event.where(game_id: @game.id).any? then return true end
        # for 'add new events' functionality: grab events w/ game id, and subtract from API events (for ex: live-updating)

      events = fetch_data(get_shifts_url)["data"]
      byebug unless events.any?
      events_by_team =
      events.
      select do |event|
        event["teamId"] == @team.team_id end

      goal_events =
      events_by_team.
      select { |event|
        event["typeCode"] == 505
      }
      shift_events_by_team = events_by_team - goal_events

      inserted_events =
      create_events (shift_events_by_team)
      create_log_entries (inserted_events)

      inserted_goal_events =
      create_goal_events goal_events
      couple_api_and_created_events(goal_events, inserted_goal_events)
      create_goal_log_entries

      inserted_events.any?
    end

    def create_events (shift_events_by_team)
      made_events_array =
      shift_events_by_team.
      map do |event|
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
      events_changes = SQLOperations.sql_insert_all("events", made_events_array )
      # grab events
      if events_changes > 0
        inserted_events = Event.order(id: :desc).limit(events_changes) #*2
      end
    end

    # map log entries for each event
    # (these players and profiles should already exist by now)
    def create_log_entries (inserted_events)
      new_log_entries_data =
      inserted_events.
      map do |event|
        records_hash = get_profile_by ({
          player_id_num: event.player_id_num
        })
        byebug if records_hash[:profile] == nil
        [event, records_hash]
      end

      new_log_entries_array =
      new_log_entries_data.
      map do |event, records_hash|
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

    end #create_game_events

    # create events; and then log entries for player_profiles involved in the event
    def create_goal_events(goal_events)
      made_events_array =
      goal_events.
      map do |event|
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

      events_changes =
      SQLOperations.
      sql_insert_all("events", made_events_array )
      # just use value of Changes() and ORDER DESC LIMIT ...

      if events_changes > 0
        inserted_events =
        Event.order(id: :desc).limit(events_changes)
      end
    end

    def create_goal_log_entries
      # aggregate prepared log_entries' hash arrays
      made_log_entries_array =
      make_new_scorers_log_entries + make_new_assisters_log_entries

      log_entries_changes = SQLOperations.sql_insert_all("log_entries", made_log_entries_array )
    end

    def make_new_scorers_log_entries
      # retrieve event and player_profile records
      made_scorers_data = @api_and_created_events_coupled.
      map do |api_event, created_evt|
        records_hash = get_profile_by({
            player_id_num: api_event["playerId"]
          })
        [created_evt, records_hash]
      end

      made_scorers_log_entries =
      made_scorers_data.
      map do |created_evt, records_hash|
        Hash[
          event_id: created_evt.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "goal",
          created_at: Time.now,
          updated_at: Time.now
        ]
      end
    end

    def make_new_assisters_log_entries

      coupled_have_assisters = @api_and_created_events_coupled.
      select do |api_event, created_evt|
        api_event["eventDetails"]
      end

      made_assisters_data =
      coupled_have_assisters.
      map do |api_event, created_evt|
        assisters = []
        # get UP TO two full names, separated by comma and space
        api_event["eventDetails"].
        gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) do |z|
          assisters << $~
        end # could use %w, per assister
        # retrieve player profile records
        assisters_data =
        assisters.map do
          |player|
          if assisters.find_index(player) == 0
            action_type = "primary"
          else action_type = "secondary" end
          records_hash = get_profile_by ({
              first_name: player["first_name"],
              last_name: player["last_name"]
            })
          Hash[ records: records_hash, action_type: action_type ]
        end

        [assisters_data, created_evt ]
      end

      made_assisters_log_entries =
      made_assisters_data.
      map do |assisters_data, created_evt|
        assisters_data.
        map do |assister|
          Hash[
            event_id: created_evt.id,
            player_profile_id: assister[:records][:profile].id,
            action_type: assister[:action_type],
            created_at: Time.now,
            updated_at: Time.now
          ]
        end
      end.flatten

    end #get_new_assisters_log_entries

    def couple_api_and_created_events(api_events, inserted_events)
      @api_and_created_events_coupled =
      api_events.
      map do |evnt|
        created_event =
        inserted_events.
        find do |ins_evnt|
          ins_evnt.end_time == evnt["endTime"] end
        [evnt, created_event]
      end
    end

    # get game's player_profile, of roster player (via  NHLRosterAPI.rb)
    # roster > players; game > player_profiles; player > player_profiles
    def get_profile_by (**search_hash)
      #cross-reference passed attributes (search_hash keys) with roster players
      player =
      @roster.players.
      find do |plyr|
        search_hash.keys.
        map do |key|
          search_hash[key] == plyr.send(key)
        end.all?
      end
      player_profile =
      @game.player_profiles.
      find do |profile|
          profile.player_id == player.id end

      byebug unless player_profile
      Hash[ profile: player_profile ]
    end
    # http://www.nhl.com/stats/rest/shiftcharts?cayenneExp=gameId=2018020008
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

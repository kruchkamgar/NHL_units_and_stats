=begin
Get the shifts events from API and call SynthesizeUnits functionality
-

make this a standalone or mixin-only module for gameAPI module?
=end


module NHLGameEventsAPI

  class Adapter

    SHIFT_CHARTS_URL = 'http://www.nhl.com/stats/rest/shiftcharts'

    def initialize (team:, game:, roster:)
      @team, @game, @roster = team, game, roster
    end

    def create_game_events

      shift_events = fetch_data(get_shifts_url)["data"]
      shift_events_by_team = shift_events.select { |event|
        event["teamId"] == @team.team_id
      }
      special_events = shift_events_by_team.delete_if { |event|
        event["eventDescription"]
      }

      # if @game.game_id.to_s[5].to_i > 1 then byebug end

      # special_events = []
      shift_events_by_team.each do |event|

        # if event["eventDescription"] then special_events << event; next; end

        new_event = Event.find_or_create_by(
          event_type: event["eventDescription"] ||= "shift", #API lists null, except for goals
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id
        )

        # (these players and profiles should already exist by now)
        records_hash = get_player_and_profile_by (:player_id, event["playerId"])

        # NHL API currently omits the per-shift position of players
        # could manually edit based on known line combinations (player 1 plays center when on unit alongside players 2, 3)
        LogEntry.find_or_create_by(
          event_id: new_event.id,
          player_profile_id: records_hash[:profile].id,
          action_type: "shift"
        )
      end

      create_special_game_events special_events

      shift_events.any?
    end #create_game_events

    private

    def create_special_game_events special_events

      special_events.each do |event|

        new_event = Event.find_or_create_by(
          event_type: event["eventDescription"],
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"],
          player_id_num: event["playerId"],
          game_id: @game.id
        )

        # create a log entry per assister(s)
        assisters= []
        event["eventDetails"].gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) { |m| assisters << $~ }

          # get UP TO two full names separated by comma and space
          assisters.each { |player|
            records_hash = get_player_and_profile_by ({
              first_name: player["first_name"], last_name: player["last_name"]
            })

            LogEntry.find_or_create_by(
              player_profile_id: records_hash[:profile].id
              event_id: new_event.id,
              action_type: "assist"
            )
          }

        # get goal-scorer by API playerId
        records_hash = get_player_and_profile_by (:player_id, event["playerId"])

        LogEntry.find_or_create_by(
          event_id: new_event.id,
          player_profile_id: player_profile.id,
          action_type: event
        )
      end

    end
    # player_profile_id: (
    #   PlayerProfile.find_by(
    #     player_id: (
    #       player = Player.find_by(
    #         last_name: player["last_name"],
    #         first_name: player["first_name"]
    #       ).id ).last #player_id # *1
    #   ).id ), # player_profile_id

    # get player and player_profile on record (created in NHLRosterAPI.rb), using the event playerId via the API.
    # roster > players; game > player_profiles; player > player_profiles
    def get_player_and_profile_by (**search_hash)
      player = @roster.players.find_by (search_hash)
      byebug unless player
      player_profile = @game.player_profiles.find_by(player_id: player.id)

      byebug unless player_profile

      { player: player, profile: player_profile }
    end
=begin
player = @roster.players.find { |player|
  player.player_id == playerId
}
byebug unless player
player_profile = @game.player_profiles.find { |profile|
  profile.player_id == player.id
}
byebug unless player_profile
=end

    def get_shifts_url
      "#{SHIFT_CHARTS_URL}?cayenneExp=gameId=#{@game.game_id}"
    end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

  end #class Adapter
end


=begin
*1- (nevermind, as API omits player positions per-shift) perhaps process the goal events, after synthesizing the units, to cross-reference the corresponding player profile matching the assist.
  .- check the time of the event against the players' shifts' times
    .=> player_profile.logs.select { |log| log.start_time < event.time < log.end_time }
=end

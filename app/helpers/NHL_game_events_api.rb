=begin
Get the shifts events from API and call SynthesizeUnits functionality
-

make this a standalone or mixin-only module for gameAPI module?
=end


module NHLGameEventsAPI

  class Adapter

    SHIFT_CHARTS_URL = 'http://www.nhl.com/stats/rest/shiftcharts'

    def initialize (game_id:)
      @game_id = game_id
    end

    def create_game_events
      shift_events = fetch_data(get_shifts_url)["data"]
      if @game_id.to_s[4].to_i > 1 then byebug end
      shift_events.each do |event|

        new_event = Event.find_or_create_by(
          event_type: event["eventDescription"] ||= "shift", #API lists null, except for goals
          duration: event["duration"],
          start_time: event["startTime"],
          end_time: event["endTime"],
          shift_number: event["shiftNumber"],
          period: event["period"]
        )

        Log.find_or_create_by(
          event_id: new_event.id,
          player_profile_id: PlayerProfile.find_or_create_by(player_id: event["playerId"]).id,
          action_type: "shift"
        )

        # get UP TO two full names separated by comma and space
        if event["eventDetails"]
          assisters= []
          event["eventDetails"].gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) { |m| assisters << $~ }


          assisters.each { |player|
            Log.find_or_create_by(
              player_profile_id: (
                PlayerProfile.find_by(
                  player_id: (
                    player = Player.find_or_create_by(
                      last_name: player["last_name"],
                      first_name: player["first_name"]
                    ).id ).last #player_id # *1
                ).id ), # player_profile_id
              event_id: new_event.id,
              action_type: "assist"
            )
          }
        end
      end
    end #create_game_events

    private

    def get_shifts_url
      "#{SHIFT_CHARTS_URL}?cayenneExp=gameId=#{@game_id}"
    end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

  end #class Adapter
end


=begin
*1- perhaps process the goal events, after synthesizing the units, to cross-reference the corresponding player profile matching the assist.
=end

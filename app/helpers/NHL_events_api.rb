=begin
Get the shifts events from API and call SynthesizeUnits functionality
-
=end


module NHLEventsAPI

  class Adapter

    def create_game_events
      shift_events = fetch_data(get_shifts_url)["data"]

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
          player_id: Player.find_or_create_by(player_id: event["playerId"]).id,
          action_type: "shift"
        )

        # get UP TO two full names separated by comma and space
        if event["eventDetails"]
          assisters= []
          event["eventDetails"].gsub(/(?<player_name>(?<first_name>[^,\s]+)\s(?<last_name>[^,]+))/) { |m| assisters << $~ }


          assisters.each { |player|
            Log.find_or_create_by(
              player_id: Player.find_by(
                last_name: player["last_name"],
                first_name: player["first_name"]
              ).id,
              event_id: new_event.id,
              action_type: "assist"
            )
          }
        end
      end
    end


  end
end

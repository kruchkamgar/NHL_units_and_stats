
=begin
fetches the game information:
- create the game; record 'home-side'
- needs to find_or_create_by the roster info
-
--> should perhaps trigger the event information in the NHLeventAPI module
=end

module NHLGameAPI

  class Adapter

      SHIFT_CHARTS_URL = 'http://www.nhl.com/stats/rest/shiftcharts'

      BASE_GAME_URL = 'https://statsapi.web.nhl.com/api/v1/game/'


    def initialize (game_id: )
      @game_id = game_id
      # author_name_split = author.split(" ") # ["Roald", "Dahl"]
    end

    def create_game
      game = Game.find_or_create_by(game_id: @game_id)
      #rewrite to check the roster against the given line-up; create a new one if no matching rosters exist.
      fetch_data(get_game_url)["teams"].map do |side, team_hash|
        game.home_side = team_hash["team"]["name"] if side == "home"
        # byebug

#move this into the ::NHLPlayersAPI module
        team_hash["players"].each { |id, player_hash|
          individual = player_hash["person"]

          Player.find_or_create_by(
            first_name: individual["firstName"],
            last_name: individual["lastName"],
            position: individual["primaryPosition"]["name"],
            position_type: individual["primaryPosition"]["type"],
            player_id: individual["id"]
          )
        }
      end
    end

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


    def get_lines_from_shifts

      # puts JSON.pretty_generate(data)
      roster_sample = get_fwds_roster
      shifts = fwds_shift_events(roster_sample) #find the shifts matching the roster sample

      period_chron = shifts_into_periods (shifts)
      lines = get_lines (period_chron)
      lines.uniq! { |line| line.sort.first}
      lines.each { |unit|
        # build a unit
        # build a circumstance
          # add a player
      }
      byebug
    end

  # private

=begin
  organize shifts into chronological order within an array  --(linked list application?)
      OR into hash with keys as the times, or shift number

      #LINE criteria: fwds' shifts starting prior and after a [reference] player's shifts
        - minimum overlapping duration


=end

    def get_shifts
      fwd_shifts = shift_events.select { |shift|
        #any shifts have player ID, matching with the roster?
          roster_hash.any? { |player|
              shift["playerId"] == roster_hash[player[0]]["person"]["id"]
          }
        }

    end

    def get_fwds_roster
      fwds_roster = Player.all.select { |player|
        player.position_type == "Forward"
      }
    end

    def shifts_into_periods (shift_events)
      period_chron = {1 => nil, 2 => nil, 3 => nil}

      period_chron.each { |period, v|

        period_chron[period] = shift_events.select { |event_h|
          event_h["duration"] && event_h["period"] == period  #make sure the events have a duration
        }.sort { |shft_a, shft_b|
          shft_a["startTime"] <=> shft_b["startTime"]
        }
      }

      period_chron
    end

    def get_lines p_chron
      minimum_shift_length = "00:30" # __ one std deviation from median shift length
      line_length = 3 # 5 possible fwds overlapping

      lines_instances = []
      p_chron.each { |period|
        i=0; period = period[1]
        while i < (period.length-1)
          if period[i]["duration"] > minimum_shift_length

            shift = period[i..-1].first(line_length)
            if mutual_overlap(shift)

              lines_instances << shift.map { |shift|
                shift["lastName"]
              }

            end
          end
          i+=1
        end
      }
      lines_instances
    end

    def mutual_overlap (shift_group)
      # refine: set minimum ice-time shared
      shifts_array = shift_group.clone
      overlap_test = []
      while shifts_array.length > 1
        base_shift = shifts_array.shift

        overlap_test << shifts_array.all? { |shift|
            #shift overlap definition:
            #shift ends after base shift starts
            #...without starting after base shift ends
            base_shift["endTime"] > shift["startTime"] && base_shift["startTime"] < shift["endTime"]
        }
      end

      overlap_test.all? { |iteration| iteration }
    end


    def get_shifts_url
      "#{SHIFT_CHARTS_URL}?#{get_params}"
    end

    def get_game_url
      "#{BASE_GAME_URL}#{@game_id}/boxscore"
    end

    def get_params
      "cayenneExp=gameId=" + "#{@game_id}"
    end

    # def get_game_id
    #   # input the the desired game ID
    #   # "2017020001"
    # end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

    def pretty_generate (item)
      puts JSON.pretty_generate(item)
    end
  end
end


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
      GAME_BASE_URL = 'https://statsapi.web.nhl.com/api/v1/game/'


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

#move this into the ::NHLRosterAPI module
# add a player module to compare/sync player records? (primary-position change for example) 
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

    def get_shifts_url
      "#{SHIFT_CHARTS_URL}?#{get_params}"
    end

    def get_game_url
      "#{GAME_BASE_URL}#{@game_id}/boxscore"
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


# *(note: linked lists generally useful for temporal traversal?)

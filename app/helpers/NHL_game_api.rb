
=begin
fetches the game information:
- create the game; record 'home-side'
- needs to find_or_create_by the roster info
- create the player_profile for this game;
- and create the roster
--> should perhaps trigger the event information in the NHLeventAPI module
=end

module NHLGameAPI

  class Adapter

      GAME_BASE_URL = 'https://statsapi.web.nhl.com/api/v1/game/'

    def initialize (game_id: )
      @game_id = 2017020019
      # author_name_split = author.split(" ") # ["Roald", "Dahl"]
    end

    def create_game
      game = Game.find_or_create_by(game_id: @game_id)
      # game.roster =

      #handles roster creation
      # handle new player profiles? (primary-position change for example)
      teams_hash = fetch_data(get_game_url)["teams"].each do |side, team_hash|
        game.home_side = team_hash["team"]["name"] if side == "home"
      end

      return [game, teams_hash]
    end

    def get_game_url
      "#{GAME_BASE_URL}#{@game_id}/boxscore"
    end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

    def pretty_generate (item)
      puts JSON.pretty_generate(item)
    end

  end
end


# *(note: linked lists generally useful for temporal traversal?)

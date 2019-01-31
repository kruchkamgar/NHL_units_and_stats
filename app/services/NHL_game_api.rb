
=begin
fetches the game information:
- create the game; record 'home-side'
- needs to find_or_create_by the roster info
- create the player_profile for this game;
- and create the roster
--> should perhaps trigger the event information in the NHLeventAPI module
=end

module NHLGameAPI

  GAME_BASE_URL = 'https://statsapi.web.nhl.com/api/v1/game/'

  class Adapter

    def initialize (game_id: )
      @game_id = game_id #2017020019
    end

    def create_game
      game =
      Game.find_or_create_by(game_id: @game_id)
      # handle new player profiles? (primary-position change for example)
      teams_hash =
      fetch_data(get_game_url)["teams"]
      teams_hash.
      each do |side, team_hash|
        if side == "home"
          game.home_side = team_hash["team"]["name"] end
        game.save
      end
      return [game, teams_hash]
    end

  private

    def get_game_url
      "#{GAME_BASE_URL}#{@game_id}/boxscore"
    end

    def fetch_data (url = nil)
      data = JSON.parse(RestClient.get(url))
    end

  end
end


# *(note: linked lists generally useful for temporal traversal?)

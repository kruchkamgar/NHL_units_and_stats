
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

    # handle new player profiles? (primary-position change for example)
    def create_game
      game = Game.find_by(game_id: @game_id)
      teams_hash =
      fetch_data(get_game_url)["teams"]
      home_side =
      teams_hash.select do |side, team_hash|
        side == "home" end
      home_side_name = home_side["home"]["team"]["name"]

      if game
          game.home_side = home_side_name
          game.save
      else
        game =
        Game.create(game_id: @game_id, home_side: home_side_name)
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

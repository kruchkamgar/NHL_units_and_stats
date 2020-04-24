
=begin
fetches the game information:
- create the game; record 'home-side'
- fetches the API listing of players for the game rosters, via the 'boxscore'

=end

module NhlGameApi

  class Adapter
  include NhlGameApi

    def initialize (game_id: )
      @game_id = game_id #2017020019
    end

    def create_game
      game = Game.find_by(game_id: @game_id)
      teams_hash =
      fetch_data(get_game_url)["teams"]
      home_side =
      teams_hash
      .select do |side, team_hash|
        side == "home" end
      home_side_name = home_side["home"]["team"]["name"]

      if game
          game.home_side = home_side_name
          game.save
      else
        game =
        Game.create(
          game_id: @game_id,
          home_side: home_side_name ) end
      return [game, teams_hash]
    end

  end #Adapter

  GAME_BASE_URL = 'https://statsapi.web.nhl.com/api/v1/game/'

  def get_game_url
    "#{GAME_BASE_URL}#{@game_id}/boxscore"
  end

  def fetch_data (url = nil)
    data = JSON.parse(RestClient.get(url))
  end

end


# *(note: linked lists generally useful for temporal traversal?)

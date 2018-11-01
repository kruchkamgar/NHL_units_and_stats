

module NHLRosterAPI

  #handles roster creation
  # handle new player profiles? (primary-position change for example)

  def self.create_game_roster (team_hash, team, game)
    # check if roster already exists [to save on work]
    roster = team.rosters.select { |roster|
      roster.players.all? { |player|
        team_hash["players"].include? "ID#{player.player_id}"
      }
    }.first

    # new players likely show up in the game's rosters first
    if roster
      roster.games << game
      roster.save
    else
      roster = team.rosters.build

      team_hash["players"].each { |id, player_hash|
        individual = player_hash["person"]

        player = Player.find_or_create_by(
          first_name: individual["firstName"],
          last_name: individual["lastName"],
          player_id: individual["id"]
        )
        player.player_profiles.find_or_create_by(
          position: player_hash["position"]["name"],
          position_type: player_hash["position"]["type"],
          player_id: player.id
        )
        roster.players << player
        roster.games << game
      }
      roster.save
    end

  end

  class Adapter

  ROSTER_URL = 'https://statsapi.web.nhl.com/api/v1/teams' #/ID for specific team

  def initialize (*team_ids, season:, player_hash: nil)
    @team_ids = team_ids.join(',')
    @season = season
  end

  def fetch_roster
    roster = JSON.parse(RestClient.get(get_url))

    roster["teams"].each { |roster_hash|
      roster_hash["roster"]["roster"].each { |player|

        player_name = /(?<first_name>[^\s]+)\s(?<last_name>[^\s]+)/.match(
          player["person"]["fullName"]
        )

        Player.find_or_create_by(
          player_id: player["person"]["id"],
          first_name: player_name["first_name"],
          last_name: player_name["last_name"]
        )
      }
    }

    # return roster hash; or call # self.class.create_game_roster, first


  end


    def get_url
      "#{ROSTER_URL}?#{teams_params}#{season_params}"
    end

    def teams_params
      "teamId=#{@team_ids}"
    end

    def season_params
      roster = "&expand=team.roster"
      season = "&#{@season}"
      roster += season if @season
    end


  end
end

#https://statsapi.web.nhl.com/api/v1/teams?teamId=4,5,29&expand=team.roster&season=20142015

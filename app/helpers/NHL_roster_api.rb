=begin

- make players and player_profiles from API
- connect game with player_profiles

assocation structure:
roster > player > player_profile;
game > player_profile
=end


#handles roster creation
# handle new player profiles? (primary-position change for example)
# new players likely show up in the games' rosters first
module NHLRosterAPI

  # probably do this in SQL statements instead
  #https://stackoverflow.com/questions/5288283/sql-server-insert-if-not-exists-best-practice
  def self.create_game_roster (team_hash, team, game)
    @team_hash, @team, @game = team_hash, team, game

    # check if roster already exists [to save on work]
    # "players" : { "ID8474709" : { "person" : { "id" : 8474709,
    player_id_nums = team_hash["players"].keys.map { |key| key.match(/\d+/)[0].to_i }

    roster_exists = Roster.includes("players").where(players: { player_id_num: player_id_nums }).references(:players)

    unless roster_exists
      @roster = team.rosters.build
    end
    # roster_exists = team.rosters.select { |rstr|
    #   rstr.players.map(&:player_id).sort == team_hash["players"].keys.map { |playerId| playerId.match(/\d+/)[0].to_i }.sort
    #     # should check player_profiles, additionally
    # }.first

    values_players = team_hash["players"].map {
        |id, player_hash|
        person = player_hash["person"]

        [
          "'#{person["firstName"]}'",
          "'#{person["lastName"]}'",
          person["id"],
          "'#{Time.now}'", "'#{Time.now}'"
        ]
      }

    sql_values_plyrs = "( #{values_players.map { |value|
      value.join(',')
    }.join('),(')} )"

    # INSERT EXCEPT for existing players
    sql_players = "INSERT INTO players (first_name, last_name, player_id_num, created_at, updated_at)
    VALUES #{sql_values_plyrs}"

    begin
      ApplicationRecord.connection.execute(sql_players)
    rescue StandardError => e
      puts "\n\n error: \n\n #{e}"
    end

    if ApplicationRecord.connection.execute("SELECT Changes()").first["changes()"] == 1
      new_players = Player.where(player_id: player_id_nums) #if inserted_players == 1

      @roster.players << new_players
    end



    values_profiles = new_players.each { |player|
    # find the player by playerId in the team_hash
      player_hash = team_hash["players"].find {|id,
        player_hash|
        player_hash["person"]["id"] == player.id
      }
      [
        player_hash["position"]["name"],
        player_hash["position"]["type"],
        player.id
      ]
    # create the sql column values array
    }

    values_profiles = "( #{values_profiles.map { |value|
      value.join(',')
    }.join('),(')} )"

    sql_player_profiles = "INSERT INTO player_profiles (position, position_type, player_id)
    VALUES #{values_profiles}"
    insert_profiles = ApplicationRecord.connection.execute(sql_player_profiles)



    # @roster.games << @game
    # @game.player_profiles << new_players.map(&:player_profiles).flatten if new_players.any?

      # if new players inserted, then create a new roster
        #- SELECT changes() (return count of affected rows as integer)
      # create new player profiles based on retrieved, added players
      # add new player_profile to game


    # check if selected roster already associates to this game, before adding duplicatively

    @roster
  end

=begin
(old code)
    if roster_exists && roster_exists.players.any?
      @roster = roster_exists
      @roster.games << game unless roster_exists.games.any? { |g| g == @game }

      @roster.save
      add_profiles_to_game
    else
      @roster = team.rosters.build

      team_hash["players"].each { |id, player_hash|
        individual = player_hash["person"]

        player = Player.find_or_create_by(
          first_name: individual["firstName"],
          last_name: individual["lastName"],
          player_id: individual["id"]
        )
        player_profile = player.player_profiles.find_or_create_by(
          position: player_hash["position"]["name"],
          position_type: player_hash["position"]["type"],
          player_id: player.id
        )
        @game.player_profiles << player_profile
        @roster.players << player
      }

      @game.save
      @roster.games << @game
      @roster.save
    end
=end


  # add all the profiles, defined by their position listed in the team_hash—(from Game API)
  def self.add_profiles_to_game
    @team_hash["players"].each { |id, player_hash|

      player = Player.find_by(
        player_id: player_hash["person"]["id"]
      )
      player_profile = player.player_profiles.find_by(
        position: player_hash["position"]["name"]
      )
      @game.player_profiles << player_profile
    }
    @game.save
  end

  ROSTER_URL = 'https://statsapi.web.nhl.com/api/v1/teams' #/ID for specific team

  class Adapter

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

  end #class Adapter
end

#https://statsapi.web.nhl.com/api/v1/teams?teamId=4,5,29&expand=team.roster&season=20142015

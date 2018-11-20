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

    roster_exists = Roster.includes(players: [:player_profiles]).where(players: { player_id_num: player_id_nums }).references(:players).first #*1

      @players = roster_exists.players

    new_player_id_nums = player_id_nums.reject { |id_num|
      roster_exists.players.map(&:player_id_num).include? id_num
    } if roster_exists
    #becomes nil if roster_exists.players fails to match player_id_nums

    if !roster_exists || new_player_id_nums.any?
      @roster = team.rosters.build

      new_players_array = team_hash["players"].map {
          |id, player_hash|
          person = player_hash["person"]

          [
            "'#{person["firstName"]}'",
            "'#{person["lastName"]}'",
            person["id"],
            "'#{Time.now}'", "'#{Time.now}'"
          ]
        }

      insert_players = new_players_array.map { |value|
          value.join(',')
        }

      sql_players = "INSERT INTO players (first_name, last_name, player_id_num, created_at, updated_at) VALUES ( #{insert_players.join('),(')} )"

      begin
        ApplicationRecord.connection.execute(sql_players)
      rescue StandardError => e
        puts "\n\n error: \n\n #{e}"
      end

      # if updates to database occurred (inserts)
      if ApplicationRecord.connection.execute("SELECT Changes()").first["changes()"] == 1
        inserted_players = Player.where(player_id_num: new_player_id_nums) #if inserted_players == 1

        @players = @roster.players << inserted_players
      end
    end #if new_players.any?

    # determine if any new profiles exist in the team_hash
    new_profiles = @players.map do |player|
      # find the player by playerId in the team_hash
        player_hash = team_hash["players"].find {|id,
          plyr_hash|
          plyr_hash["person"]["id"] == player.player_id_num
        }[1]
        # skip if player_profile already exists
        next if player.player_profiles.map(&:position).include? player_hash["position"]

        Hash[
          position: player_hash["position"]["name"],
          position_type: player_hash["position"]["type"],
          player_id: player.id
        ]
      # create the sql column values array
      end

    created_profiles = PlayerProfile.create(new_profiles).first
    @game.player_profiles << created_profiles.flatten
    @game.save

    # @roster.games << @game
    # @game.player_profiles << new_players.map(&:player_profiles).flatten if new_players.any?

      # if new players inserted, then create a new roster
        #- SELECT changes() (return count of affected rows as integer)
      # create new player profiles based on retrieved, added players
      # add new player_profile to game


    # check if selected roster already associates to this game, before adding duplicatively
    @roster.games << @game unless roster_exists.games.any? { |g| g == @game }
    @roster.save
    @roster
  end

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

    def sql_insert (table, values)
      # values_profiles = "( #{new_profiles.map { |value|
      #   value.join(',')
      # }.join('),(')} )"
      #
      # sql_player_profiles = "INSERT INTO player_profiles (position, position_type, player_id)
      # VALUES #{values_profiles}"
      # insert_profiles = ApplicationRecord.connection.execute(sql_player_profiles)
    end

  end #class Adapter
end

#https://statsapi.web.nhl.com/api/v1/teams?teamId=4,5,29&expand=team.roster&season=20142015


# *1-
# roster_exists = team.rosters.select { |rstr|
   #   rstr.players.map(&:player_id).sort == team_hash["players"].keys.map { |playerId| playerId.match(/\d+/)[0].to_i }.sort
   #     # should check player_profiles, additionally
   # }.first

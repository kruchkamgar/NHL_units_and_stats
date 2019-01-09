=begin

- make rosters, from players and player_profiles derived from GAME API
- connect game with player_profiles

Adapter
- fetch given roster(s) from NHL API

assocation structure:
roster > player > player_profile;
game > player_profile
=end


#handles roster creation
module CreateRoster

  # probably do this in SQL statements instead
  #https://stackoverflow.com/questions/5288283/sql-server-insert-if-not-exists-best-practice

  def self.create_game_roster

    roster_and_players_creation_logic

    create_new_profiles # (if they exist)

    # @game.player_profiles << created_profiles.flatten
    add_profiles_to_game

    @roster
  end

  def self.query_for_roster_and_id_new_plyrs
    player_id_nums = team_hash["players"].keys.map { |key| key.match(/\d+/)[0].to_i }

    roster_exists = Roster.includes(players: [:player_profiles]).where(players: { player_id_num: player_id_nums }).references(:players).first #*1

      # collect potential new players, if roster exists
      if roster_exists
        new_player_id_nums = player_id_nums.reject { |id_num|
          roster_exists.players.map(&:player_id_num).include? id_num
        }
      else new_player_id_nums = player_id_nums end
  end

  def self.roster_and_players_creation_logic (team_hash, team, game)
    @team_hash, @team, @game = team_hash, team, game

    # check if roster already exists [to save on work] *3
    # "players" : { "ID8474709" : { "person" : { "id" : 8474709,
    player_id_nums = team_hash["players"].keys.map { |key| key.match(/\d+/)[0].to_i }

    roster_exists = Roster.includes(players: [:player_profiles]).where(players: { player_id_num: player_id_nums }).references(:players).first #*1

      # collect potential new players, if roster exists
      if roster_exists
        new_player_id_nums = player_id_nums.reject { |id_num|
          roster_exists.players.map(&:player_id_num).include? id_num
        }
      else new_player_id_nums = player_id_nums end

    if roster_exists && roster_exists.games.include?(@game) # && roster.game (no new players if includes game). !roster_exists || new_player_id_nums.any?
      @roster = roster_exists
      @players = roster_exists.players
    elsif new_player_id_nums.any?
      @roster = team.rosters.build

# >>? check first if player exists, as opposed to letting database handle uniqueness for player_id_nums
# - team_hash players.any? { |player| Player.all.include? player }
      new_players_array = team_hash["players"].map {
          |id, player_hash|
          person = player_hash["person"]

          Hash[
            first_name: person["firstName"],
            last_name: person["lastName"],
            player_id_num: person["id"],
            created_at: Time.now,
            updated_at: Time.now
          ]
        }

      players_changes = SQLOperations.sql_insert_all("players", new_players_array )

      if players_changes > 0
        inserted_players = Player.order(id: :desc).limit(players_changes)

        # Player.where(player_id_num: new_player_id_nums) #if inserted_players == 1
        @roster.save
        @players = @roster.players << inserted_players
      end

      add_game_to_roster
    end # if roster_exists
  end

  def self.add_game_to_roster
    @roster.games << @game
  end

  # create new profile for player, if team_hash (via player_hash) contains new position. *4
  def self.create_new_profiles
    new_profiles_data = @players.
    map do
      |player|
      # find the player by playerId in the team_hash
      api_player_hash = team_hash["players"].find {
        |id, plyr_hash|
        player.player_id_num == plyr_hash["person"]["id"]
      }[1]

      [player, api_player_hash]
    end.
    reject do |player, api_player_hash|
      # reject if player's player_profile already exists
      player.player_profiles.map(&:position).include? api_player_hash["position"]["name"]
    end

    new_profiles_array = new_profiles_data.map do |player, api_player_hash|
        # then create hash if not exists
        Hash[
          position: api_player_hash["position"]["name"],
          position_type: api_player_hash["position"]["type"],
          player_id: player.id,
          created_at: Time.now,
          updated_at: Time.now
        ]
      end

    profiles_changes = SQLOperations.sql_insert_all("player_profiles", new_profiles_array ) unless new_profiles_array.empty? # *3 (incomplete)
  end

  # add [to game] all the database profiles found for the player positions listed in team_hash
  def self.add_profiles_to_game
    players = @players.includes(:player_profiles)
    player_profiles = @team_hash["players"].map do |id, player_hash|
        player = players.find { |player|
            player.player_id_num == player_hash["person"]["id"]
          }
        # return the matching player_profile
        player.player_profiles.find { |profile|
          profile.position == player_hash["position"]["name"]
        }
      end
    @game.player_profiles += (player_profiles - @game.player_profiles)

     # if (@game.player_profiles & player_profiles).empty? # '&' operator tests array overlap
  end


  # ////////////////// fetch roster(s) from API ////////////////// #

  ROSTER_URL = 'https://statsapi.web.nhl.com/api/v1/teams' #/ID for specific team

  class Adapter

    def initialize (*team_ids, season:, player_hash: nil)
      @team_ids = team_ids.join(',')
      @season = season
    end

    # [unused] secondary function, for now
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


# *1-
# roster_exists = team.rosters.select { |rstr|
   #   rstr.players.map(&:player_id).sort == team_hash["players"].keys.map { |playerId| playerId.match(/\d+/)[0].to_i }.sort
   #     # should check player_profiles, additionally
   # }.first

# *2-
# handles new player profiles because:
# (primary-position change for example)
# - new profiles exhibited in the new game rosters;
# - new players likely show up in the games' rosters first

# *3- (incomplete)
# existing roster check currently forgoes checking for new [or different lineups (combinations) of] player_profiles

# *4- even while containing the same exact players in full, a new game roster could have a new position listed for a player (thus necessitating a new player profile)

=begin

- make players and player_profiles from API
- connect game with player_profiles

assocation structure:
roster > player > player_profile;
game > player_profile
=end


#handles roster creation
module CreateRoster

  # probably do this in SQL statements instead
  #https://stackoverflow.com/questions/5288283/sql-server-insert-if-not-exists-best-practice
  def self.create_game_roster (team_hash, team, game)
    @team_hash, @team, @game = team_hash, team, game

    # check if roster already exists [to save on work] *3
    # "players" : { "ID8474709" : { "person" : { "id" : 8474709,
    player_id_nums = team_hash["players"].keys.map { |key| key.match(/\d+/)[0].to_i }

    roster_exists = Roster.includes(players: [:player_profiles]).where(players: { player_id_num: player_id_nums }).references(:players).first #*1

    if roster_exists
      new_player_id_nums = player_id_nums.reject { |id_num|
        roster_exists.players.map(&:player_id_num).include? id_num
      }
    else new_player_id_nums = player_id_nums end
      #becomes nil if roster_exists.players fails to match player_id_nums

=begin
  (refactor: logic)

  if roster_exists
    if new_player_id_nums
      build_new_roster
    end
  else
    build_new_roster
  end
=end

    if !roster_exists || new_player_id_nums.any?
      @roster = team.rosters.build

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
        inserted_players = Player.where(player_id_num: new_player_id_nums) #if inserted_players == 1
        @roster.save
        @players = @roster.players << inserted_players
      end
    else
      @roster = roster_exists
      @players = roster_exists.players
    end #if new_players.any?

    # determine if any new profiles exist in the team_hash data from API
    new_profiles_array = @players.map do |player|
        # find the player by playerId in the team_hash
        player_hash = team_hash["players"].find {|id,
          plyr_hash|
          plyr_hash["person"]["id"] == player.player_id_num
        }[1]
        # skip if player's player_profile already exists, by position
        next if player.player_profiles.map(&:position).include? player_hash["position"]["name"]

        # then create hash if not exists
        Hash[
          position: player_hash["position"]["name"],
          position_type: player_hash["position"]["type"],
          player_id: player.id,
          created_at: Time.now,
          updated_at: Time.now
        ]
      end.compact

    profiles_changes = SQLOperations.sql_insert_all("player_profiles", new_profiles_array ) unless new_profiles_array.empty? # *3 (incomplete)

    # @game.player_profiles << created_profiles.flatten
    add_profiles_to_game

    # check if selected roster already associates to this game, before adding duplicatively

    @roster.games << @game unless @roster.games.include? @game
    @roster
  end

  # add all the profiles. Position defines profiles -position as listed in the team_hash—(from Game API)
  def self.add_profiles_to_game
    players = @players.includes(:player_profiles)
    player_profiles = @team_hash["players"].map do |id, player_hash|
        player = players.find { |player|
            player.player_id_num == player_hash["person"]["id"]
          }
        player.player_profiles.find { |profile|
          profile.position == player_hash["position"]["name"]
        }
      end
    @game.player_profiles += player_profiles if (@game.player_profiles & player_profiles).empty? # '&' operator tests array overlap
  end

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

# *2-
# handles new player profiles because:
# (primary-position change for example)
# - new profiles exhibited in the new game rosters;
# - new players likely show up in the games' rosters first

# *3- (incomplete)
# existing roster check currently forgoes checking for new [or different combinations of] player_profiles

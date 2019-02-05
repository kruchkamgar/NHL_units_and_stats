=begin

- make rosters, from players and player_profiles derived from GAME API
- connect game with player_profiles

Adapter
- fetch given roster(s) from NHL API

assocation structure:
roster > player > player_profile;
game > player_profile
rosters >< games
=end

#handles roster creation
module CreateRoster

  def self.create_game_roster (team_hash, team, game)
    @team_hash, @team, @game = team_hash, team, game

    roster_record_data =
    query_for_matching_roster()
    roster_and_players_creation_logic(roster_record_data)
    map_player_records_to_api()
    # new profiles may manifest, for matched rosters too, in @game
    inserted_profiles =
    create_new_profiles()
    add_profiles_to_game(inserted_profiles)
    @roster
  end

  def self.query_for_matching_roster
    player_id_nums =
    @team_hash["players"].keys.
    map do |key|
      key.match(/\d+/)[0].to_i end

    roster_record =
    Roster.
    includes(players: [:player_profiles]).
    where(players: { player_id_num: player_id_nums }).
    references(:players).first #*1
    # collect potential new players, if roster exists
    if roster_record
      new_player_id_nums =
      player_id_nums.
      reject do |id_num|
        roster_record.players.map(&:player_id_num).include? id_num end
    else new_player_id_nums = player_id_nums end
    Hash[
      roster_record: roster_record,
      n_p_ids: new_player_id_nums,
      p_ids: player_id_nums ]
  end

  # if new players exist (and no matching roster found, therefore) @game brings a NEW roster
  def self.roster_and_players_creation_logic (data)
    roster_record = data[:roster_record]; new_player_id_nums = data[:n_p_ids];

    if new_player_id_nums.any? &&
      !( roster_record.games.include?(@game) if roster_record )# blocks api game roster update contingency, which could bring new players
      @roster = @team.rosters.build
# >>? check first if player exists, as opposed to letting database handle uniqueness for player_id_nums
# - team_hash players.any? { |player| Player.all.include? player }
      new_players_array =
      @team_hash["players"].
      select do |id, player_hash|
        new_player_id_nums.include? player_hash["person"]["id"] end.
      map do |id, player_hash|
        person = player_hash["person"]
        Hash[
          first_name: person["firstName"],
          last_name: person["lastName"],
          player_id_num: person["id"],
          created_at: Time.now,
          updated_at: Time.now ]
      end
      players_changes = SQLOperations.sql_insert_all("players", new_players_array )

      @roster.players <<
      Player.where(player_id_num: data[:p_ids] )
      @roster.games << @game
      @roster.save
    else
      @roster = roster_record
      @roster.games << @game unless @roster.games.include?(@game)
    end # if ...
  end #roster_and_players_creation_logic

  def self.map_player_records_to_api
    @player_records_to_api =
    @roster.players.
    map do |player|
      api_player_hash =
      @team_hash["players"].
      find do |id, plyr_hash|
        player.player_id_num == plyr_hash["person"]["id"] end[1]
      [player, api_player_hash]
    end
  end #map_player_records_to_api

  def self.create_new_profiles
    @existing_profiles_data =
    @player_records_to_api.
    select do |player, api_player_hash|
      player.player_profiles.map(&:position).include? api_player_hash["position"]["name"]
    end

    new_profiles_data = @player_records_to_api - @existing_profiles_data

    new_profiles_array =
    new_profiles_data.
    map do |player, api_player_hash|
      # then create hash if not exists
      Hash[
        position: api_player_hash["position"]["name"],
        position_type: api_player_hash["position"]["type"],
        player_id: player.id,
        created_at: Time.now,
        updated_at: Time.now
      ]
    end

    if new_profiles_array.any? # *3 (incomplete)
      profiles_changes = SQLOperations.sql_insert_all("player_profiles", new_profiles_array )

      PlayerProfile.order(id: :desc).limit(profiles_changes)
    end
  end

  # add all the database profiles found in team_hash, to @game
  def self.add_profiles_to_game (inserted_profiles)

    # players_records =
    # @roster.players.
    # includes(:player_profiles)
    # player_profiles =
    # @team_hash["players"].
    # map do |id, plyr_hash|
    #   record =
    #   players_records.
    #   find { |record|
    #     record.player_id_num == plyr_hash["person"]["id"] }
    #   # return the matching player_profile
    #   record.player_profiles.
    #   find { |profile|
    #     profile.position == plyr_hash["position"]["name"] }
    # end
    game_profiles =
    @existing_profiles_data.
    map do |record, api_hash|
      record.player_profiles.
      find do |profile|
        profile.position == api_hash["position"]["name"] end
    end

    @game.player_profiles +=
    (
      game_profiles +
      (inserted_profiles || []) - @game.player_profiles ) # existing + inserted - pre-existing
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

      roster["teams"].
      each do |roster_hash|
        roster_hash["roster"]["roster"].
        each do |player|
          player_name = /(?<first_name>[^\s]+)\s(?<last_name>[^\s]+)/.
          match( player["person"]["fullName"] )
          Player.
          find_or_create_by(
            player_id: player["person"]["id"],
            first_name: player_name["first_name"],
            last_name: player_name["last_name"] )
        end
      end #each
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
# roster_record = team.rosters.select { |rstr|
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

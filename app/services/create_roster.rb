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

    query_for_matching_roster()
    roster_and_players_creation_logic()
    map_player_records_to_api()
    # new profiles may manifest - even for matched rosters too - in this new @game
    inserted_profiles =
    create_new_profiles()
    add_profiles_to_game(inserted_profiles)
    @roster
  end

  def self.query_for_matching_roster

    @player_id_nums =
    @team_hash["players"].keys
    .map do |key|
      key.match(/\d+/)[0].to_i end

    @roster_record =
    Roster
    .joins(:players)
    .where(id:
      Roster.select(:id).distinct
      .joins(:players)
      .where(players: { player_id_num: @player_id_nums })
      .where(team_id: @team)
      .group(:id)
      .having("COUNT(rosters.id) = ?", @player_id_nums.size) )
    .group("rosters.id")
    .having("COUNT(rosters.id) = ?", @player_id_nums.size )
    .preload(players: [:player_profiles]) || nil

  end

  # if new players exist (and no matching roster found, therefore) @game brings a NEW roster
  def self.roster_and_players_creation_logic

    unless @roster_record.any?

      @roster = @team.rosters.build

      players_data = get_new_api_data_and_records()
      roster_players = create_new_players(*players_data)
# performance: bulk insert where '<<'
      @roster.players << roster_players
      @roster.games << @game
      @roster.save
    else
      @roster = @roster_record[0]
      @roster.games << @game unless @roster.games.pluck(:game_id).include?(@game.game_id)
    end # if ...
  end #roster_and_players_creation_logic

  def self.get_new_api_data_and_records
    player_records =
    Player.where(player_id_num: @player_id_nums)
    new_players_api_data =
    @team_hash["players"]
    .select do |id, player_hash|
      @player_id_nums
      .include? player_hash["person"]["id"] end

    # new minus existing players
    new_players =
    new_players_api_data
    .reject do |id, player_hash|
      player_records
      .map(&:player_id_num)
      .include? player_hash["person"]["id"] end

# byebug
    [new_players, player_records]
  end

  def self.create_new_players(new_players, player_records)
    if new_players.any?
      prepared_players =
      new_players
      .map do |id, player_hash|
        person = player_hash["person"]

        # SQL escape for apostrophes
        fN = person["firstName"]; lN = person["lastName"];
        if fN.include?("'")
          fN.insert(fN.index("'"), "'") end
        if lN.include?("'")
          lN.insert(lN.index("'"), "'") end

        Hash[
          first_name: fN,
          last_name: lN,
          player_id_num: person["id"],
          created_at: Time.now,
          updated_at: Time.now ]
      end
      players_changes = SQLOperations.sql_insert_all("players", prepared_players )
      roster_players =
      Player.order(id: :desc).limit(players_changes) + player_records
    else roster_players = player_records end
  end

  def self.map_player_records_to_api
    @player_records_with_api_data =
    @roster.players
    .preload(:player_profiles)
    .map do |player|
      api_player_hash =
      (@team_hash["players"]
      .find do |id, plyr_hash|
        player.player_id_num == plyr_hash["person"]["id"] end || byebug)[1]
      [player, api_player_hash]
    end
  end #map_player_records_to_api

  # difference b/n player records and api profiles
  def self.create_new_profiles
    new_profiles_data =
    @player_records_with_api_data
    .reject do |player, api_player_hash|
      player.player_profiles.map(&:position).include? api_player_hash["position"]["name"]
# use primary position to avoid "Unknown"
    end

    @existing_profiles_data = @player_records_with_api_data - new_profiles_data

    new_profiles_array =
    new_profiles_data
    .map do |player, api_player_hash|
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

    game_profiles =
    @existing_profiles_data
    .map do |record, api_hash|
      record.player_profiles
      .find do |profile|
        profile.position == api_hash["position"]["name"] end
    end
#performance: do a prepare-insert instead perhaps
    @game.player_profiles +=
    ( game_profiles +
      (inserted_profiles || []) - @game.player_profiles ) # existing + inserted - pre-existing. --use #union [for arrays]?
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

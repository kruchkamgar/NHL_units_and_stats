require 'create_roster'
require_relative './data/team_hash'
require_relative './data/players'

# create game
# create roster w/ and without the game; (roster could exist without this game)


describe CreateRoster do
  before(:context) do
    Team.destroy_all
    @team = Team.create(id: 100, team_id: 1, name: "New Jersey Devils", created_at: Time.now, updated_at: Time.now)
    byebug

    @sample_players = sample_players.map do |player|
      Player.new(player) end
    @players = team_hash["players"].map.with_index(1) do |id, index|
        plyr_hash = team_hash["players"]["#{id[0]}"]
        Player.new(
          id: index,
          first_name: plyr_hash["firstName"],
          last_name: plyr_hash["lastName"],
          player_id_num: plyr_hash["person"]["id"]
        )
      end

  end

  context 'where roster has game:' do
    before(:context) do
      @roster = Roster.new(team_id: 1)
      @game = Game.new(id: 1, home_side: "New Jersey Devils")
    end

    describe '#roster_and_players_creation_logic' do
      it 'sets @roster and @players' do
        roster_w_game = @roster
        roster_w_game.games << @game
        roster_w_game.players << @sample_players

        allow(Roster).to receive_message_chain(:includes, :where, :references, :first) { roster_w_game }

        subject.roster_and_players_creation_logic(team_hash, @team, @game)

        expect(subject.instance_variable_get(:@roster)).to eq(roster_w_game)
        expect(subject.instance_variable_get(:@players)).to eq(@sample_players)
      end
    end
  end

  context 'does not have game:' do
    before(:context) do
      @roster = Roster.new(team_id: 1)
      @players_sample = @players.first(5).clone
      # @roster.players << @players_sample # 5 players
      # # let(:team_hash_players) { team_hash["players"]}
      @game = Game.new(id: 1, home_side: "New Jersey Devils")
    end

    after(:context) do @roster.destroy end

    describe '#roster_and_players_creation_logic' do

      it 'builds roster and adds game' do
        allow(Roster).to receive_message_chain(:includes, :where, :references, :first) { @roster }

        subject.roster_and_players_creation_logic(team_hash, @team, @game)

        expect(subject.instance_variable_get(:@roster)).to be_kind_of(Roster)
        expect(subject.instance_variable_get(:@roster).games).to include(@game)
      end

      it 'creates players' do
        allow(SQLOperations).to receive(:sql_insert_all).with("players", an_object_satisfying { |collection| collection.size == 22 }).and_return(17)

        allow(Player).to receive_message_chain(:order, :limit).with(17).and_return(@players_sample)

        subject.roster_and_players_creation_logic(team_hash, @team, @game)

        expect(subject.instance_variable_get(:@players)).to eq(@players_sample)
      end
    end
  end # context 'does not have game'

  context '...' do

    before(:context) do
      # CreateRoster.instance_variable_get(:@roster).games.destroy_all
      # CreateRoster.instance_variable_get(:@game).destroy
      # CreateRoster.instance_variable_get(:@roster).players.destroy_all
      # CreateRoster.instance_variable_get(:@players).destroy
      @players_sample = @players.first(5).clone
      @sample_profiles = sample_profiles.map do |profile|
        PlayerProfile.new(profile) end
    end
    after(:context) do
      # @players.each { |player| player.player_profiles.destroy_all }
    end

    describe '#create_new_profiles' do
      before(:example) do
        @players_sample.each_with_index do |player, i|
        player.player_profiles << @sample_profiles[i] if @sample_profiles[i] end
      end

      it 'creates hash and calls insert' do
        subject.instance_variable_set(:@players, @players_sample)

        allow(SQLOperations).to receive(:sql_insert_all).with(
          "player_profiles", a_collection_including(
              a_hash_including(player_id: 4, player_id: 5)
            )
        ).and_return(2)

        expect(subject.create_new_profiles).to eq(2)
      end
    end

    describe '#add_profiles_to_game' do
      before(:example) do
        # for some reason, 'creates players' example above results in 'created_at / updated_at' fields on @player_profiles, having non-nil values...
        @player_profiles = team_hash["players"].map.with_index(1) do |id, index|
            plyr_hash = team_hash["players"]["#{id[0]}"]
            PlayerProfile.new(
              id: index,
              position: plyr_hash["position"]["name"],
              position_type: plyr_hash["position"]["type"],
              player_id: index
            )
          end
        @players.each_with_index do |player, i|
          player.player_profiles << @player_profiles[i] end
      end

      it 'adds profiles' do
        subject.instance_variable_set(:@players,
        Player)

        subject.instance_variable_set(:@game,
        Game.new)

        allow(Player).to receive(:includes).and_return(@players)

        expect(subject.add_profiles_to_game.first(3).map(&:position)).to eq(@sample_profiles.map(&:position))
      end
    end
  end

end

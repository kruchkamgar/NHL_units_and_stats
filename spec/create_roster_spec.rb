require 'create_roster'
require_relative './data/team_hash'
require_relative './data/players_and_profiles'

# create game
# create roster w/ and without the game; (roster could exist without this game)


describe CreateRoster do
  before(:context) do
    @init_index = 100
    @team = Team.create(id: 101, team_id: 2, name: "New York Islanders", created_at: Time.now, updated_at: Time.now)
    @team_hash = team_hash_02

    @sample_players = sample_players.map do |player|
      Player.new(player) end
    @players = @team_hash["players"].
    map.with_index(0) do |id, index|
        plyr_hash = @team_hash["players"]["#{id[0]}"]
        Player.new(
          id: (index + @init_index),
          first_name: plyr_hash["firstName"],
          last_name: plyr_hash["lastName"],
          player_id_num: plyr_hash["person"]["id"]
        )
      end
  end

  let(:initializer) {
    CreateRoster.instance_variable_set(:@team_hash, @team_hash)
    CreateRoster.instance_variable_set(:@team, @team)
  }
  let(:run_logic) { subject.roster_and_players_creation_logic(@data) }

  context 'where roster has game:' do
  before(:context) do
    @roster = Roster.new(team_id: 101)
    @game = Game.new(id: 2, home_side: "New York Islanders") end
  # seems to destroy it automatically -- after(:context) do @game.destroy end

  describe '#query_for_roster_and_new_plyrs' do
    it 'retrieves matching roster record from db' do
      initializer

      roster_w_game = @roster
      roster_w_game.games << @game
      roster_w_game.players << @sample_players

      allow(Roster).
      to receive_message_chain(:includes, :where, :references, :first).
      and_return roster_w_game

      expect(CreateRoster.query_for_roster_and_new_plyrs).
      to include(
        roster_record: a_kind_of(Roster),
        pids: a_collection_including(
          a_kind_of(Integer) )
      )
    end
  end

    before(:example) do
      @data = Hash[roster_record: @roster, pids: []]
    end
    # CreateRoster.instance_variable_set(:@game, @game)
    describe '#roster_and_players_creation_logic' do
      it 'sets @roster and @players' do
        CreateRoster.instance_variable_set(:@game, @game)

       run_logic
        expect(subject.instance_variable_get(:@roster)).to eq(@roster)
        expect(subject.instance_variable_get(:@players)).to eq(@sample_players)
      end
    end
  end # context 'where roster has game'

  context 'does not have game:' do
    before(:context) do
      @players_sample = @players.first(5).clone

      @data = Hash[roster_record: @roster, pids: [12345, 23456]]
    end

    describe '#roster_and_players_creation_logic' do
      before(:example) do
        @game = Game.new(id: 2, home_side: "New York Islanders")
        CreateRoster.instance_variable_set(:@game, @game)
      end

      it 'builds roster and adds game' do
        run_logic
        expect(subject.instance_variable_get(:@roster)).to be_kind_of(Roster)
        expect(subject.instance_variable_get(:@roster).games).to include(@game)
      end

      it 'creates players' do
        allow(SQLOperations).to receive(:sql_insert_all).with("players", an_object_satisfying { |collection| collection.size == 22 }).and_return(17)

        allow(Player).to receive_message_chain(:order, :limit).with(17).and_return(@players_sample)
        run_logic
        expect(subject.instance_variable_get(:@players)).
        to eq(@players_sample)
      end
    end
  end # context 'does not have game'

  context '-' do

    before(:context) do
      # CreateRoster.instance_variable_get(:@roster).games.destroy_all
      # CreateRoster.instance_variable_get(:@game).destroy
      # CreateRoster.instance_variable_get(:@roster).players.destroy_all
      # CreateRoster.instance_variable_get(:@players).destroy
      @players_sample = @players.first(5).clone
      @sample_profiles = sample_profiles # NYI
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
        subject.instance_variable_set(:@team_hash, @team_hash)

        allow(SQLOperations).to receive(:sql_insert_all).with(
          "player_profiles", a_collection_including(
             hash_including(player_id: @init_index + 4),
             hash_including(player_id: @init_index + 3),
             hash_excluding(player_id: @init_index + 2)
            )
        ).and_return(2)

        expect(subject.create_new_profiles).to eq(2)
      end
    end

    # use the seeds instead
    describe '#add_profiles_to_game' do
      before(:example) do
        # for some reason, 'creates players' example above results in 'created_at / updated_at' fields on @player_profiles, having non-nil values...
        @player_profiles = @team_hash["players"].map.with_index do |id, index|
            plyr_hash = @team_hash["players"]["#{id[0]}"]
            PlayerProfile.new(
              id: (index + @init_index),
              position: plyr_hash["position"]["name"],
              position_type: plyr_hash["position"]["type"],
              player_id: (index + @init_index)
            )
          end
        @players.each_with_index do |player, i|
          player.player_profiles << @player_profiles[i] end
      end

      it 'adds profiles' do # *1 *2
        roster_players_dbl =
        double('@roster.players')

        subject.instance_variable_set(:@players,
        roster_players_dbl)
        subject.instance_variable_set(:@game,
        Game.new)

        allow(roster_players_dbl).
        to receive(:includes).
        and_return(@players)

        # sample_profiles contains first (3) @player_profiles?
        expect(
          subject.
          add_profiles_to_game.first(3).
          map(&:position) ).
        to eq(
          @sample_profiles.
          map(&:position) )
      end
    end
  end

end

=begin
  *1 - (refactor)
  use doubles to reflect intentions - readability?

  *2 -
  could also use generic seeds, used across multiple tests
=end

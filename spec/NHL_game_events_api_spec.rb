require 'NHL_game_events_api'
require_relative './shared_examples/an_SQL_insert'
require_relative './data/shift_events'
require_relative './data/players_and_profiles'

describe 'NHLGameEventsAPI' do
  before(:context) do
    @team = Team.new(id: 100, team_id: 1)
    @game_id = 2017020019
    @game = Game.new(id: 1, home_side: "New Jersey Devils")
    @roster = Roster.new(team_id: 100)

    @roster.players << team_hash_players.clone
    API = Event::API
  end

  let(:adapter) {
    allow(Game).to receive_message_chain(:where, :includes, :[]).and_return(@game)
    allow(Roster).to receive_message_chain(:where, :includes, :[]).and_return(@roster)

    NHLGameEventsAPI::Adapter.new(team:
    @team, game: @game, roster: @roster)
  }
  let(:sample_profile) { PlayerProfile.new(sample_profiles.first) }
  let(:get_profile_by_stub) {
    allow(adapter).to receive(:get_profile_by) { {profile: sample_profile} }
  }

  let(:test_keys) { ["start_time", "end_time", "period", "player_id_num"] }
  let(:insert_queue_test_keys) {
    test_keys.map do |key|
      API[key.to_sym] end
    }

  let(:test_inclusion_hash) { lambda do |insert_queue_hash|
      Hash[
        test_keys.map do |key|
          [  key.to_sym,
            insert_queue_hash[API[key.to_sym]] ] end
      ]
  end }

  context 'for regular events:' do
    before (:context) {
      @shift_events_by_team = shift_events_by_team.clone
    }
    let(:inserted_records) { adapter.create_events(@shift_events_by_team) }
    before (:example) { @sample_event = @shift_events_by_team.sample }


  describe '#create_events' do
    it 'makes an array of hashed events' do
      allow(SQLOperations).to receive(:sql_insert_all).with(
        "events",
        a_collection_including(
          hash_including(
            test_inclusion_hash[@sample_event]
        ) )
      ).and_return(1)
      allow(Event).to receive(:where) { false }

      expect(adapter.create_events(@shift_events_by_team)).to eq( false )
    end

    it_behaves_like 'an SQL insert' do
      let(:insert_queue) { @shift_events_by_team }
    end

  end # describe #create_events

  describe '#create_log_entries' do

    it 'makes an array of hashed log entries data, returning "true"' do
      get_profile_by_stub

      allow(SQLOperations).to receive(:sql_insert_all).with(
        "log_entries",
        a_collection_including(
          hash_including(
            event_id: inserted_records.sample.attributes["id"],
            action_type: "shift"
        ) )
      ).and_return(1)

      expect(adapter.create_log_entries(inserted_records)).to eq(1)
    end
  end
  end # context 'regular events'

  context 'for goal events:' do
    before (:context) { @goal_events = goal_events.clone }
    before (:example) { @sample_event = @goal_events.sample }
    let(:inserted_records) { adapter.create_goal_events(@goal_events) }


  describe '#create_goal_events' do
    it 'makes an array of hashed events' do
      allow(SQLOperations).to receive(:sql_insert_all).with(
        "events",
        a_collection_including(
          hash_including(
            test_inclusion_hash[@sample_event]
        ) )
      ).and_return(1)
      allow(Event).to receive(:find_by_sql) { false }

      expect(inserted_records).to eq( false )
    end

    it_behaves_like 'an SQL insert' do
      let(:insert_queue) { @goal_events }
    end
  end

  let(:api_and_created) {
      Array.new(5) do |index|
        [ @goal_events.sample, Event.new(id: index) ]
      end
    }
  describe '#make_new_assisters_log_entries' do
    it 'makes array of hashed log entries data' do

      get_profile_by_stub
      adapter.instance_variable_set(:@api_and_created_events_coupled, api_and_created)

      expect(adapter.make_new_assisters_log_entries).
      to include(
        hash_including(
          action_type: "secondary",
          event_id: (a_value < 6)
      ) )
    end
  end

  describe '#make_new_scorers_log_entries' do
    it 'makes array of hashed log entries data' do

      get_profile_by_stub
      adapter.instance_variable_set(:@api_and_created_events_coupled, api_and_created)
      # test if has the assister fed, and for its correct action_type
      # prob just pass in 2 'created events' w/ api events
      expect(adapter.make_new_scorers_log_entries).
      to include(
        a_hash_including(
          action_type: "goal",
          event_id: (a_value < 6)
      ) )
    end
  end

  # describe '#create_goal_log_entries' do
  #   it '' do
  #
  #   end
  # end

  end # context 'for goal events:'

  let(:profile_search_hash) {
    Hash[ player_id_num: 101, last_name: "Williams" ] }
  before (:example) do
    @test_players =
    Array.new(sample_players.size) { |index|
       Player.new(sample_players[index]) }
    @test_profiles =
    Array.new(sample_profiles.size) { |index|
      PlayerProfile.new(sample_profiles[index]) }
    @test_players.
    each_with_index do |plyr, index|
      plyr.player_profiles << @test_profiles[index] end
    @game.player_profiles << @test_profiles
  end

  describe '#get_profile_by' do
    it 'returns a hash of key :profile' do
      roster_dbl = double('roster')
      game_dbl = double('game')
      allow(roster_dbl).to receive(:players) { @test_players }
      allow(game_dbl).to receive(:player_profiles) { @test_profiles }

      adapter.instance_variable_set(:@roster, roster_dbl)
      adapter.instance_variable_set(:@game, game_dbl)

      expect(adapter.get_profile_by(profile_search_hash)
    ).to eq(
      Hash[
        profile: (
          @test_players.
          find do |player|
            player.player_id_num == 101
          end.
          player_profiles.first
        ) ]
      )
    end
  end

end

=begin
  (refactor):
  goal events could insert in the same statement; as their RETRIEVALS operate independently of their insert sequence (neither uses #changes)
=end

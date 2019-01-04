require 'NHL_game_events_api'
require_relative './data/shift_events'
require_relative './data/players_and_profiles'

describe NHLGameEventsAPI do
  before(:context) do
    @shift_events_by_team = shift_events_by_team.clone
    @shift_events_by_team_create_events = shift_events_by_team_create_events.clone
    @game_id = 2017020019
    @game = Game.new(id: 1, home_side: "New Jersey Devils")
    @team = Team.new(id: 100)
    @roster = Roster.new(team_id: 100)

    @roster.players << team_hash_players.clone
  end

  let(:adapter) {
    allow(Game).to receive_message_chain(:where, :includes, :[]).and_return(@game)

    allow(Roster).to receive_message_chain(:where, :includes, :[]).and_return(@roster)

    NHLGameEventsAPI::Adapter.new(team:
    @team, game: @game, roster: @roster)
  }

  let(:ends_and_randoms) { x = Random.new(1)
    array_size = @shift_events_by_team.size
    values = [0, array_size-1] # always include first and last
    5.times do
     values << (x.rand(array_size-2)+1)
    end
    values
   }
  let(:inserted_events) { adapter.create_events(@shift_events_by_team) }

  describe '#create_events' do
    it 'returns an array of hashed and SQL-inserted events' do
        expect(
          inserted_events.
          map do |evt|
            this = evt.attributes.
            select do |key|
               ["start_time", "end_time", "period", "player_id_num"].include? key
            end.
            values.
            sort do |a, b|
              a.to_s <=> b.to_s end
          end.
          values_at(*ends_and_randoms)
        ).to eq( @shift_events_by_team_create_events.values_at(*ends_and_randoms))
    end
  end

  describe '#create_log_entries' do
    let(:sample_profile) { PlayerProfile.new(sample_profiles.first) }

    it 'builds an array of hashed log entries data, returning "true"' do
      allow(adapter).to receive(:get_profile_by) { {profile: sample_profile} }

      allow(SQLOperations).to receive(:sql_insert_all).with(
        "log_entries",
        a_collection_including(
          hash_including(
            event_id: inserted_events.sample.attributes["id"],
            action_type: "shift"
        ) )
      ).and_return(1)

      expect(adapter.create_log_entries(inserted_events)).to eq(true)
    end
  end

  describe

end

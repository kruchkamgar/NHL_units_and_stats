require 'create_units_and_instances'
require_relative './data/events_hashes'
require_relative './data/players_and_profiles'

describe 'CreateUnitsAndInstances' do
  before(:context) do
    create_events_sample
    Event.all.
    each do |event|
      LogEntry.create(
        event_id: event.id,
        action_type: event.event_type,
        player_profile_id:
          Player.find_by(player_id_num: event.player_id_num).player_profiles.first.id
      ) end
    @roster = CreateUnitsAndInstances.instance_variable_set(:@roster, Roster.first)
    @game = CreateUnitsAndInstances.instance_variable_set(:@game, Game.first)
  end

  # describe 'make_units_and_instances' do
  #
  # end

  describe '#get_roster_sample' do
    let(:player_types) { UNIT_HASH[3] }
    it 'selects forwards from a roster' do
      expect(
        CreateUnitsAndInstances.get_roster_sample(player_types).map do |plyr|
          plyr.player_profiles.first end
        ).to all(have_attributes(position_type: "Forward"))
    end
  end

  describe '#get_shifts' do
    let(:roster_sample) { @roster.players.first(2) }
    it 'selects events of sampled players' do

      player_id_nums = roster_sample.map(&:player_id_num)
      expect(
        CreateUnitsAndInstances.get_shifts(roster_sample).map(&:player_id_num).uniq.sort
      ).to eq(player_id_nums.sort)
    end
  end

  let(:shift_events) {
    Event.where(event_type: "shift", game_id: @game.id ) }

  describe '#shifts_into_periods' do
    it 'groups shifts into hash of periods' do
      expect(
        CreateUnitsAndInstances.shifts_into_periods(shift_events)
      ).
      to include(
        3 => a_collection_including( a_kind_of(Event) ),
        1 => a_collection_including( a_kind_of(Event) )
      )
    end
  end

  describe '#make_instances_events' do
    let(:period_hash) { Hash[
        1 => Event.all.sample(6),
        2 => Event.all.sample(6)
      ] }

    it 'makes array of arrays of events' do
      allow(CreateUnitsAndInstances).to receive(:mutual_overlap).with(
        a_collection_including(
          a_kind_of(Event)
        ) 
      ) { true }

      expect(
        CreateUnitsAndInstances.make_instances_events(period_hash, UNIT_HASH.keys.first)
      ).
      to a_collection_including(
        a_collection_including(
          a_kind_of(Event)
      ) )
    end
  end

  describe '#mutual_overlap' do
    let(:shifts_overlap) {
      events_with_db_keys(sample_shifts_overlap).map do |shift|
        Event.new(shift) end
      }
      it "returns true, testing full array elements' overlap" do
        expect(
          CreateUnitsAndInstances.mutual_overlap(shifts_overlap)
        ).to eq( true )
      end

      let(:shifts_disparate) {
        events_with_db_keys(sample_shifts_disparate).map do |shift|
          Event.new(shift) end
        }
        it "returns false, testing such overlap" do
          expect(
            CreateUnitsAndInstances.mutual_overlap(shifts_disparate)
          ).to eq( false )
        end
  end
end # CreateUnitsAndInstances

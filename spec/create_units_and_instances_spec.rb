require 'create_units_and_instances'
require_relative './data/create_events_from_hashes'
require_relative './data/players_and_profiles'

describe 'CreateUnitsAndInstances' do
  before(:context) do
    create_events_sample #larger than sample from seeds
    @roster = CreateUnitsAndInstances.instance_variable_set(
      :@roster, Roster.where(team_id: 1).first
    )
    player_id_nums =
    @roster.players.
    map(&:player_id_num)
    #from create_events_sample--
    Event.where(player_id_num: player_id_nums ).
    each do |event|
      LogEntry.create(
        event_id: event.id,
        action_type: event.event_type,
        player_profile_id:
          Player.find_by(player_id_num: event.player_id_num).player_profiles.first.id
      ) end

    @game = CreateUnitsAndInstances.instance_variable_set(:@game, Game.first)
  end

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

  # insts = instances.call.map do |e| [e[:start_time], e[:end_time], e[:events].map do |ev| [ev.start_time, ev.end_time, Player.find_by_player_id_num(ev.player_id_num).last_name] end] end; pp insts

  # insts = instances.map do |e| [e[:start_time], e[:end_time], e[:events].map do |ev| [e[:events].size, ev.start_time, ev.end_time, Player.find_by_player_id_num(ev.player_id_num).last_name] end ] end; pp insts
  describe '#form_instances_by_events' do
    let(:forwards) {
      @roster.players.
      select do |plyr|
        plyr.player_profiles.first.
        position_type == "Forward" end.
      map(&:player_id_num) }
    let(:period_hash) {
      Hash[
        1 => Event.where(event_type: 'shift', period: 1 ).
        where(player_id_num: forwards).order(start_time: :asc).to_a.
        sort_by! do |shft|
          [shft.start_time, shft.end_time] end
        # 2 => Event.where(event_type: 'shift' ).first(12)
      ] }

    it 'forms array of arrays of events', :overlaps do
      expect(
        CreateUnitsAndInstances.form_instances_by_events(period_hash, UNIT_HASH.keys.first)
      ).
      to a_collection_including(
        hash_including(
          :events => a_collection_including(a_kind_of(Event))
        ),
        an_object_satisfying { |event|
          event[:start_time] == "00:37" }
      )
    end
  end

  # describe '#mutual_overlap' do
  #   let(:shifts_overlap) {
  #     events_with_db_keys(sample_shifts_overlap).map do |shift|
  #       Event.new(shift) end
  #     }
  #     it "returns true, testing full array elements' overlap" do
  #       expect(
  #         CreateUnitsAndInstances.mutual_overlap(shifts_overlap)
  #       ).to eq( true )
  #     end
  #
  #     let(:shifts_disparate) {
  #       events_with_db_keys(sample_shifts_disparate).map do |shift|
  #         Event.new(shift) end
  #       }
  #       it "returns false, testing such overlap" do
  #         expect(
  #           CreateUnitsAndInstances.mutual_overlap(shifts_disparate)
  #         ).to eq( false )
  #       end
  # end

  let(:units_groups_hash) {
    abc_events = Event.all.sample(3)
    abc_player_id_nums =
    abc_events.map(&:player_id_num)
    Hash[
      [123, 234, 345] => [ Event.all.sample(3), Event.all.sample(3) ],
      [543, 432, 321] => [ Event.all.sample(3), Event.all.sample(3) ],
      abc_player_id_nums => [ abc_events ]
    ]
  }
  let(:units) {
    units_groups_hash.keys.
    map.with_index do |unit, i|
      Unit.new(id: i) end }
  let(:existing_units) {
    instance = Instance.create(id: 100)
    instance.events << units_groups_hash.
                       values.last.flatten(1)
    unit =
    Unit.new(id:1); unit.instances << instance;
    unit
  }
  describe '#get_preexisting_units' do
    it 'forms an array sequenced with pre-existing units, and nils for new units' do
      allow(Unit).to receive(:includes).with(instances: [ :events ]) { [existing_units] }

      expect(
        CreateUnitsAndInstances.get_preexisting_units(units_groups_hash.keys)
      ).
      to a_collection_including(
        include(nil, nil, existing_units)
      )
    end
  end

  # if ex_and_formed_u_nils.include? (Unit.all.to_a.find do |u| u.instances.first.events.map(&:player_id_num).sort == [8471233, 8475151, 8475791] end)
  #   byebug end
  # if formed_units.
  #   any? do |u| u.sort == [8471233, 8475151, 8475791] end
  #   puts "formed_units––\n"
  #   byebug end

  describe '#create_units' do
    it '#inserts and retrieves units' do
      allow(CreateUnitsAndInstances).to receive(:get_preexisting_units).with(a_kind_of(Array)) { [nil] }
      expect(
        CreateUnitsAndInstances.create_units(units_groups_hash.keys)
      ).
      to include(
        a_kind_of(Unit)
      )
    end
  end

  # unit_players_names = Unit.all.select do |unit| unit.instances.any? end.map(&:instances).map do |inst| inst.map(&:events).map do |event| event.map do |event| Player.find_by(player_id_num: event.player_id_num).last_name end end end
  describe '#create_instances' do
    it '#inserts and retrieves instances' do
      expect(
        CreateUnitsAndInstances.create_instances(units.reverse, units_groups_hash.values)

      ).
      to include(
        a_kind_of(Instance),
        have_attributes(
          unit_id: 0,
          start_time: units_groups_hash.values.first.

          first.max_by(&:start_time).start_time # check for correct unit-instance mapping, to verify order of insertion
        )
      )
    end
  end

  #after .flatten(1): [ [event1, 2, 3], [event1, 2, 3], ... ]
  let(:new_instances) { units_groups_hash.values.flatten(1) }
  let(:inserted_instances) {
    Array.new(new_instances.size) do |index|
      Instance.new(id: index) end }

  describe '#associate_events_to_instances' do
    #test that instance_event at insert_index, matches sample instance's id.
    it 'calls sql_insert_all with made associations' do
      sample_instance_index = 3
      sample_instance = inserted_instances.reverse[sample_instance_index]
      # (made_associations index)
      sample_index =
      new_instances[0...sample_instance_index].
      inject(0) do |counts, instance|
        counts + instance.size end

      expect(SQLOperations).
      to receive(:sql_insert_all).with("events_instances",
        an_object_satisfying do |obj|
          obj[sample_index][:instance_id] == sample_instance.id end
      )

      CreateUnitsAndInstances.
      associate_events_to_instances(
        inserted_instances,
        new_instances
      )
    end
  end

end # CreateUnitsAndInstances

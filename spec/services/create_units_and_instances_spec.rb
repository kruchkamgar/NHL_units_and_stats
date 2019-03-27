# require 'create_units_and_instances'
require './spec/data/events_flow'
require './spec/data/instances_flow'
require './spec/data/players_and_profiles'

describe CreateUnitsAndInstances, :type => :service do
  before(:context) do
    CRUI = CreateUnitsAndInstances

    # create_events_sample() #larger than sample from seeds

  # runs using [old] seeds---
    # @roster = CRUI.instance_variable_set(
    #   :@roster, Roster.where(team_id: 1).first
    # )
    # player_id_nums =
    # @roster.players.
    # map(&:player_id_num)
    # #from create_events_sample--
    # Event.where(player_id_num: player_id_nums ).
    # each do |event|
    #   LogEntry.create(
    #     event_id: event.id,
    #     action_type: event.event_type,
    #     player_profile_id:
    #       Player.find_by(player_id_num: event.player_id_num).player_profiles.first.id
    #   ) end
    #
    # @game = CRUI.instance_variable_set(:@game, Game.first)
  end

  describe '#get_roster_sample' do
    let(:player_types) { UNIT_HASH[3] }
    it 'selects forwards from a roster' do
      expect(
        CRUI.get_roster_sample(player_types).map do |plyr|
          plyr.player_profiles.first end
        ).to all(have_attributes(position_type: "Forward"))
    end
  end

  describe '#get_shifts' do
    let(:roster_sample) { @roster.players.first(2) }
    it 'selects events of sampled players' do

      player_id_nums = roster_sample.map(&:player_id_num)
      expect(
        CRUI.get_shifts(roster_sample).map(&:player_id_num).uniq.sort
      ).to eq(player_id_nums.sort)
    end
  end

  let(:shift_events) {
    Event.where(event_type: "shift", game_id: @game.id ) }

  describe '#shifts_into_periods' do
    it 'groups shifts into hash of periods' do
      expect(
        CRUI.shifts_into_periods(shift_events)
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
    let(:all_player_types) {
      @roster.players.
      select do |plyr|
        position =
        plyr.player_profiles.first.
        position_type
        (position == "Defenseman" || position == "Forward" || position == "Goalie")
      end.
      map(&:player_id_num) }
    let(:period_hash) {
      Hash[
        1 => Event.where(event_type: 'shift', period: 1 ).
        where(player_id_num: all_player_types).order(start_time: :asc).to_a.
        sort_by! do |shft|
          [shft.start_time, shft.end_time] end
        # 2 => Event.where(event_type: 'shift' ).first(12)
      ] }

    # it 'forms 6-man instances', :overlaps do
    #   expect(
    #     CRUI.form_instances_by_events(period_hash)
    #   ).
    #   to a_collection_including(
    #     hash_including(
    #       :events => a_collection_including(a_kind_of(Event))
    #     ),
    #     an_object_satisfying { |event|
    #       event[:start_time] == "00:37" }
    #   )
    # end

    let(:fwds_and_d) {
      @roster.players.
      select do |plyr|
        position =
        plyr.player_profiles.first.
        position_type
        (position == "Defenseman" || position == "Forward")
      end.
      map(&:player_id_num) }
    let(:period_hash) {
      Hash[
        1 => Event.where(event_type: 'shift', period: 1 ).
        where(player_id_num: fwds_and_d).order(start_time: :asc).to_a.
        sort_by! do |shft|
          [shft.start_time, shft.end_time] end
        # 2 => Event.where(event_type: 'shift' ).first(12)
      ] }

    it 'forms 5-man instances', :overlaps do
      expect(
        CRUI.form_instances_by_events(period_hash)
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


  before(:context) do
    @team_id = 1; @game_id = 2018021020; #SeedMethods
    seed_team_and_players(); seed_game();
    @events_hashes = events_hashes_penalties()
    seed_events()
    CRUI.instance_variable_set(:@game, @game)

    @units_groups_hash = units_groups_hash_(pre_seed: true)
  end # hashes via data.rb
  describe 'creation process—-', :creation do

  describe 'incorporate instance penalty status', :penalties do
    let(:penalty_data) do
      CRUI::get_special_teams_api_data end
    it '#get_special_teams_api_data' do
      penalty_plays = CRUI::get_special_teams_api_data

      expect(penalty_data)
      .to include(a_kind_of(Hash))
    end

    it '#add_penalty_end_times' do
      penalties =
      CRUI::add_penalty_end_times(penalty_data)
      expect(penalties)
      .to include( a_hash_including(
        end_time: a_kind_of(String) ) )
    end

    it '#add_penalty_data_to_instances' do
      made_instances = CRUI::add_penalty_data_to_instances(
        units_groups, penalty_data )

      expect(made_instances)
      .to include(
        hash_including( penalty: true ) )
    end
  end # :penalties

  let(:existing_units) do end

  describe '#get_preexisting_units' do
    it 'forms an array sequenced with pre-existing units, and nils for new units' do
      # allow(Unit).to receive(:includes).with(instances: [ :events ]) { [existing_units] }
      #
      # expect(
      #   CRUI.get_preexisting_units(.keys)
      # )
      # .to a_collection_including(
      #   include(nil, nil, existing_units) )
    end
  end

  # if ex_and_formed_u_nils.include? (Unit.all.to_a.find do |u| u.instances.first.events.map(&:player_id_num).sort == [8471233, 8475151, 8475791] end)
  #   byebug end
  # if formed_units.
  #   any? do |u| u.sort == [8471233, 8475151, 8475791] end
  #   puts "formed_units––\n"
  #   byebug end

  let(:insert_units_method) do
    all_new_queue = Array.new( @units_groups_hash.size, nil )

    CRUI::insert_units(
      @units_groups_hash.keys,
      all_new_queue )
  end
    # let(:insert_with_existing_units) do
    # not_all_new_queue
    # ... end

  describe '#insert_units', :creation do
    it 'inserts and retrieves units' do
      expect(insert_units_method)
      .to include( a_kind_of(Unit) )
    end
  end

  # unit_players_names = Unit.all.select do |unit| unit.instances.any? end.map(&:instances).map do |inst| inst.map(&:events).map do |event| event.map do |event| Player.find_by(player_id_num: event.player_id_num).last_name end end end
  # let(:queued_units) do
  #   CRUI::find_or_create_units(units_groups_hash.keys) end

  let(:prepped_insts_grps) do
    prepare_instances(insert_units_method, @units_groups_hash.values) end
  describe '#prepare_instances', :creation do
    it 'prepares instances hashes for insert' do
      expect(prepped_insts_grps)
      .to include(
        a_collection_including(
          hash_including(
            unit_id: 1,
            start_time: @units_groups_hash.values.first
            .last[:start_time] # check for correct unit-instance mapping, to verify order of insertion
      ))  )
    end
  end

  describe '#create_circumstances', :creation do
    it 'creates circumstances' do
      create_circumstances = CRUI.create_circumstances(prepped_insts_grps)

      expect(create_circumstances)
      .to eq(10)
    end
  end

  #after .flatten(1): [ [event1, 2, 3], [event1, 2, 3], ... ]
  let(:new_instances) { @units_groups_hash.values.flatten(1) }
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

      expect(SQLOperations)
      .to receive(:sql_insert_all).with("events_instances",
        an_object_satisfying do |obj|
          obj[sample_index][:instance_id] == sample_instance.id end
      )

      CRUI.
      associate_events_to_instances(
        inserted_instances,
        new_instances
      )
    end
  end # associate_events_to_instances
end # describe creation process

end # CRUI

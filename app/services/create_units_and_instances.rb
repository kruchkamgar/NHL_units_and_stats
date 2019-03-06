=begin


- get shifts by team, for a game
- create instances [of units], by processing shifts

- note: will NOT look for previous instances, will create duplicates; (does look for existing units)


-- TODO -- add units-rosters relationship? (alt. find by roster players for Units' shift-events only)
=end



module CreateUnitsAndInstances
  include Utilities # time calculations

  UNIT_HASH = {
    # 2 => ["Defenseman"]
    # 2 => ["Forward"] #4-on-4 (EVGs), SH
    3 => ["Forward"],
    5 => ["Forward", "Defenseman"],
    # 6 => ["Forward", "Defenseman", "Goalie"], #6-skater
  }

  def create_records_from_shifts #(team, roster, game, units)
    # @team, @units_includes_events = team, units
    @game = Game.where(id: @game).includes(events: [:player_profiles])[0]
    @roster = Roster.where(id: @roster).includes(:players)[0]

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|
      roster_sample = get_roster_sample (unit_type)
      #find the shifts matching the roster sample
      shifts = get_shifts(roster_sample)
      # sort shifts by start time, for each period
        # {[period1 event1, 2...], [p2 event1, 2, ...] ... }
      period_chronology = shifts_into_periods (shifts)
      #find all unit instances by shift events' temporal overlaps
        # (format: array of arrays)
      instances_by_events_arrays = form_instances_by_events(period_chronology)
      units_groups_hash = group_by_players(instances_by_events_arrays)

      create_units_and_instances (units_groups_hash)
    end

  end #create_records_from_shifts

  def create_units_and_instances (units_groups_hash)
    @inserted_units = []
    queued_units =
    find_or_create_units(units_groups_hash.keys)

    queued_instances =
    create_instances(queued_units, units_groups_hash.values)

    associate_events_to_instances(
      queued_instances,
      units_groups_hash.values.
      map do |instances|
        instances.
        map do |inst_hash|
        inst_hash[:events] end
      end.flatten(1) )

    puts "\n\n @units_includes_events \n\n"
    # @units_includes_events =
    # @units_includes_events
    # .or(
    #    Unit.where(
    #      Unit.arel_table[:id].in(
    #        @inserted_units.arel_table.project(:id)) )
    #    .includes(:rosters, instances: [ :events ])
    #    .where(instances: { events: {event_type: "shift"} })
    # ).load

    associate_roster_to_units(queued_units)
  end

  def find_or_create_units (formed_units)
    new_formed_units, units_records_queue = get_preexisting_units(formed_units)

    # nils stand for new units [absent from records]
    if units_records_queue.any? nil
      units_queue =
      insert_units(new_formed_units, units_records_queue)
    else units_records_queue end
  end

  def get_preexisting_units (formed_units)
    new_formed_units = formed_units.clone
    # nils act as placeholders for queued new units. swaps pre-existing units with their records from db.
    puts "\n\n #get_preexisting_units #{formed_units.first.size} \n\n"

    units_records_queue =
    formed_units.
    map do |unit|
      bind_targets = []
      binds =
      unit.map.with_index do |value, index|
        bind_targets.push(":#{index + 1}")
        assemble_binds("player_id_num", value) end

        unit_record =
        ApplicationRecord.connection.exec_query(
          retrieve_unit_sql(bind_targets),
          "SQL",
          binds ).rows.first
        if (unit_record)
          # byebug
          new_formed_units.delete_at(new_formed_units.index(unit))
          true end
      # end #find

      Unit.find_by(id: unit_record.first) unless unit_record == nil
    end

    puts "\n\n get_preexisting_units done \n\n"

    [new_formed_units, units_records_queue]
  end

  def retrieve_unit_sql (bind_targets)
    <<~SQL
      SELECT *
      FROM units
      JOIN
        (SELECT unit_id
        FROM instances
        JOIN events_instances
        ON instance_id = instances.id
        JOIN events
        ON events.id = event_id
        WHERE instances.id IN
          (SELECT instances.id
          FROM instances
          JOIN
            (SELECT instance_id
            FROM events_instances
            WHERE event_id IN
              (SELECT id
              FROM events
              WHERE player_id_num IN (#{bind_targets.join(', ')})
                AND events.event_type = 'shift' )
            GROUP BY instance_id
            HAVING COUNT(*) >= #{bind_targets.size} )
          ON instance_id = instances.id )
        AND events.event_type = 'shift'
        GROUP BY unit_id, instance_id
        HAVING COUNT(instance_id) = #{bind_targets.size} )
      ON id = unit_id
      GROUP BY id
    SQL
  end

  def assemble_binds(field, value)
    ActiveRecord::Relation::QueryAttribute.new(field, value, ActiveRecord::Type::Integer.new)
  end

  def insert_units(formed_units, records_queue)
    prepared_units =
    formed_units.
    map do |unit|
      Hash[
        created_at: Time.now,
        updated_at: Time.now ]
    end
    units_changes =
    SQLOperations.sql_insert_all("units", prepared_units)

    if units_changes > 0
      @inserted_units =
      Unit.order(id: :desc).limit(units_changes)
    end

    # add inserted_units to @units_includes_events, ahead of assoc to roster?
    @inserted_units.reverse.
    each do |record|
      nil_i = records_queue.index(nil)
      if nil_i
        records_queue[nil_i] = record end
      end if @inserted_units.any?

    records_queue
  end

  def create_instances (queued_units, units_groups)

    prepared_instances =
    queued_units.
    map.with_index do |unit, i|
    # (create_units already reverses queued_units)
      # coincident index from source: units_groups_hash
      units_groups[i].
      map do |inst|
        Hash[
          unit_id: unit.id,
          start_time: inst[:start_time],
          duration: TimeOperation.new(:-, inst[:start_time], inst[:end_time]).result,
          created_at: Time.now,
          updated_at: Time.now ]
      end # *3
    end.flatten(1)

    instances_changes = SQLOperations.sql_insert_all("instances", prepared_instances)

    queued_instances =
    Instance.order(id: :desc).limit(instances_changes).reverse
  end

  def associate_events_to_instances(queued_instances, formed_instances)
    # insert instances; get instances; ...
    prepared_associations =
    queued_instances.
    map.with_index do |instance, i|
      formed_instances[i].map do |event|
        Hash[
          instance_id: instance.id,
          event_id: event.id ]
      end
    end.flatten

    SQLOperations.sql_insert_all("events_instances", prepared_associations)
  end

  def associate_roster_to_units(queued_units)
    puts "\n\n associate_roster_to_units \n\n"

# performance: single query for units' rosters matching @roster instead?
    queued_units_new_roster =
    queued_units.
    reject do |unit|
      unit.rosters.include? @roster end

    prepared_rosters_units =
    queued_units_new_roster.
    map do |unit|
      Hash[
        roster_id: @roster.id,
        unit_id: unit.id ]
    end

    SQLOperations.sql_insert_all("rosters_units", prepared_rosters_units) if prepared_rosters_units.any?
  end

  # ////////////////// prep methods ////////////////// #

  # filter to get certain player types (see UNIT_HASH)
  def get_roster_sample (player_types)

    roster_sample =
    @roster.players
    .select do |player|
      player_types
      .include? (
        (@game.player_profiles
        .find do |profile|
          profile.player_id == player.id end || byebug)
        .position_type)
    end
  end

  # roster -< players -< player_profiles
  # game -< player_profiles
  # get the shifts for the roster
  def get_shifts roster_sample
    # select shifts by matching to roster sample's player_profiles
    shifts =
    @game.events.
    select do |event|
      event.event_type == "shift" &&
      roster_sample.
      any? do |player|
        event.player_profiles.
        any? do |profile|
          profile.player_id == player.id end
      end
    end #select
  end #get_shifts

  def shifts_into_periods (shift_events)
    period_chron =
    shift_events
    .group_by do |event|
      event.period end
      .each do |period, events|
      events
      .sort_by! do |shft|
        [shft.start_time, shft.end_time] end
    end
  end #shifts_into_periods

  def form_instances_by_events (p_chron) # *4
    p_chron
    .map do |period, events|
      time_mark = "00:00"; queue_head = 0;
      instances = []
      while queue_head && events[queue_head]
        load_next_overlaps(queue_head, events, time_mark)
        instances_proc =
        Proc.new do |inst|
          (instances.push inst if inst) || instances end
        time_mark =
        call_overlap_test(
          [ @overlap_set.first, start_time: time_mark ],
          @overlap_set.second,
          instances: instances_proc )
        queue_head =
        reset_queue_head(queue_head, events, time_mark)
      end
      instances
    end.flatten(1)
  end #form_instances_by_events

  def call_overlap_test(basis_data, comparison_data, instances: )
    basis = make_event_hash( *basis_data )
    comparison = make_event_hash( *comparison_data )
    overlap_test( basis, comparison, instances: instances )
  end

  def make_event_hash (event=nil, **bounds)
    Hash[
      start_time: ( bounds[:start_time] || event.start_time ),
      end_time: ( bounds[:end] || event.end_time),
      event: event ] if event
  end

  def load_next_overlaps(queue_head, events, time_mark)
    byebug if @interrupt
    @overlap_set = []
    # accomodates no-length shift errors in API data
    while events[queue_head].start_time == events[queue_head].end_time
      queue_head += 1 end
    for comparison in events[queue_head..-1]
      if events[queue_head].end_time > comparison.start_time
        if time_mark < comparison.end_time
          @overlap_set.push comparison end
      else
         break end
    end # for
  end

  def reset_queue_head(queue_head, events, time_mark)
    if @overlap_set.any?
      queue_head =
      events.index(@overlap_set.first)
    else
      queue_event =
      events[queue_head..-1].
      find do |event|
        time_mark <= event.start_time end
      queue_head = events.index(queue_event)
    end
  end

  def overlap_test( basis, comparison, instances: )
    byebug if basis == nil
    n = @overlap_set.index(basis[:event])
    min_by_et = Proc.new do
      @overlap_set.min_by(&:end_time) end
    # queue_head at last shift--
    if comparison == nil
      # only one player on ice (5v3s)
      if basis[:event] == @overlap_set.first
        instances.call(
          Hash[
            events: @overlap_set.clone,
            end_time: (end_time = basis[:end_time]),
            start_time: basis[:start_time] ] )
        @overlap_set = []
        return end_time
      # last instance--
        # collect, delete,
      elsif min_by_et.call.end_time == (end_time = @overlap_set.first.end_time)
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: min_by_et.call.end_time ] )
        @overlap_set.
        delete_if do |event|
          event.end_time == end_time end
        return end_time
      # next instance--
        # collect, delete, return overlaps ending time
      else
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: (end_time = min_by_et.call.end_time) ] )
        @overlap_set.
        delete_if do |event|
          event.end_time == end_time end
        call_overlap_test(
          [ @overlap_set.first, start_time: min_by_et.call.end_time ],
          @overlap_set.second,
          instances: instances )
      end
    # start time of overlap set or instance--
      # increment queue-head
    elsif basis[:start_time] >= comparison[:start_time]
    # notes: comparison, at start of new frame, could precede basis
      call_overlap_test(
        [ comparison[:event], start_time: basis[:start_time] ],
        @overlap_set[n+2],
        instances: instances )
    #intervening start time--
    elsif basis[:start_time] < comparison[:start_time] && comparison[:start_time] < min_by_et.call.end_time
      # collect, increment queue-head
      basis_i = @overlap_set.index(basis[:event])
      instances.call(
        Hash[
          events: @overlap_set[0..basis_i].clone,
          start_time: basis[:start_time],
          end_time: comparison[:start_time] ] )
      call_overlap_test(
        comparison[:event],
        @overlap_set[n+2],
        instances: instances )
    #end of instance--
    elsif (min_et = min_by_et.call).end_time <= comparison[:start_time]
      basis_i = @overlap_set.index( basis[:event] )
      # collect, delete, reset queue-head
      instances.call(
        Hash[
          events: @overlap_set[0..basis_i].clone,
          start_time: basis[:start_time],
          end_time: min_et.end_time ] )
      @overlap_set.
      delete_if do |event|
        event[:end_time] == min_et.end_time end
      call_overlap_test(
        [ @overlap_set.first, start_time: min_et.end_time ],
        @overlap_set.second,
        instances: instances )
    end
  end

  def group_by_players(instances_by_events_hashes)
=begin
    # for [live-]updating of games? likely not useful
    if instances_by_events_hashes
      @existing_game_instances = Instance.includes("events").where( events: { game_id: @game.id })

      # subtract events of existing game instances
      @formed_instances_by_events = instances_by_events_hashes.
      reject do |inst_hash|
        @existing_game_instances.
        map do |inst|
          inst.map(&:events).
          select do |event|
            event.event_type = "shift" end
        end.
        sort_by |e| [e.player_id_num] == inst_hash[:events].
        sort_by |e| [e.player_id_num]
      end #reject
    end # if...
=end
    # {
      # [instances' player_id_nums] => [
        # { :events => [instance_by_events_1], :start_time => "00:00", :end_time => "00:01" }
        # { :events => [instance_by_events_5], :start_time => "00:20", :end_time => "00:23" }
    # ] }
    units_groups_hash =
    instances_by_events_hashes.
    group_by do |inst_hash|
      inst_hash[:events].
      map do |event|
        event.player_id_num end.sort
    end
  end #group_by_players

end
#
# =begin
#
# *1—
# instance.events.map { |event| event.log_entries.where(action_type: "shift").player_profile_id) }.sort.
#   --re: player_id_num
#
# instance.events.map { |event| event.log_entries.map(&:player_profile_id) }.flatten.uniq.sort
#
# *2-
# processing special events and shift events in same flow / methods
#
#   nui-
#   note: simply remove the NON-SHIFT / special events (with .compact?) for this step, if temporally processing all events together
#
# *3-
# instance start times derive, from the start of the overlap among all the involved players' shifts
# duration measures the time spanned in this overlap
#
# *4- (improvement?)
#  process special events for a game instead of per team
#  add an event into an instance_by_events array

  # integration means only tally +/- per game rather than for each team

#
# *5- (pattern)
# situation: if doing a live-update, one may need to update new instances for a unit
# - could use a different API for this however (w/ similar code)
# create instances for new instances_by_events only
#

# *6-
# (requirements)
# unit criteria– why no larger minimum overlap time?
#   - even a 2-second overlap can form a difference in the play (relevant unit criteria)

#   -? if using minimum overlap time, use on top of 2 or 4 plyrs (3, or 5-man unit)

# ///////////// extra ///////////// #



# =end

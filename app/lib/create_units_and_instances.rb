=begin

- get shifts by team, for a game
- create instances [of units], by processing shifts

- note: will NOT look for previous instances, will create duplicates; (does look for existing units)

-- TODO -- add units-rosters relationship? (alt. find by roster players for Units' shift-events only)
=end


module CreateUnitsAndInstances
  include Utilities # time calculations

  GAME_DATA_API =
  "https://statsapi.web.nhl.com/api/v1/game/<game_id>/feed/live/"

  UNIT_HASH = {
    5 => ["Forward", "Defenseman"]
    # 6 => ["Forward", "Defenseman", "Goalie"], #6-skater
  }

  def form_units_from_shifts(inserted_events: , roster:) #(team, roster, game, units)
    # @team, @units_includes_events = team, units
    puts "\n\n#create_records_from_shifts\n\n"

    # @game =
    # Game.where(id: @game)
    # .includes(events: [:player_profiles])[0]
    roster_incl_players =
    Roster.where(id: roster.id)
    .includes(:players)[0]

      # sample roster based on player types
      roster_sample = get_roster_sample(
        player_types: UNIT_HASH[5],
        roster_incl_players: roster_incl_players )
      # find the shifts matching the roster sample
      shifts = get_shifts(roster_sample, inserted_events)
      # sort shifts by start time, for each period
        # {[period1 event1, 2...], [p2 event1, 2, ...] ... }
      period_chronology = shifts_into_periods(shifts)
      #find all unit instances by shift events' temporal overlaps
        # (format: array of hashes)
      instances_by_events_arrays = form_instances_by_events(period_chronology)

      group_by_players(instances_by_events_arrays)
  end #create_records_from_shifts


  def create_units_instances_etc(units_groups_hash, roster: )
    queued_units =
    find_or_create_units(units_groups_hash.keys)

    queued_instances =
    create_instances_and_circumstances(
      queued_units, units_groups_hash.values)

    formed_instances =
      units_groups_hash.values
      .map do |instances|
        instances
        .map do |inst_hash|
        inst_hash[:events] end
      end.flatten(1)

    associate_events_to_instances(
      queued_instances, formed_instances )

      puts "\n\n @units_includes_events \n\n"

    associate_roster_to_units(queued_units, roster)
  end

private

  # filter to get certain player types (see UNIT_HASH)
  def get_roster_sample (player_types:, roster_incl_players: )

    roster_sample =
    roster_incl_players.players
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
  def get_shifts(roster_sample, inserted_events)
# live updating:
# use shifts >= timemark, or pass incremental shift events directly (w/ if statement)

    # select shifts by matching to roster sample's player_profiles

    shifts =
    # @game.events
    inserted_events[:events]
    .select do |event|
      event.event_type == "shift" &&
      roster_sample
      .any? do |player|
        event.player_profiles
        .any? do |profile|
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

  def form_instances_by_events (p_chron) # *4, *7
  puts "\n\n#form_instances_by_events\n\n"
  # abstract--
  # 1. use a QUEUE_HEAD to track progress;
  # 2. through iterations-(@OVERLAP_SET) of groups of events; each event of a group overlaps its "basis" (aka first) event
  # 3. create INSTANCES via proc, whenever conditions meet the criteria [recursively called on the iterations]
  # 4. return the END TIME of the last created instance (TIME_MARK), for continuity b/n iterations

  # *8- live update for shift events (NOT currently offered in API)

    p_chron
    .map do |period, events|
      # time_mark = "00:00";
      time_mark = events.first.start_time; queue_head = 0;
      instances = []
      instances_proc =
      Proc.new do |inst|
        (instances.push inst if inst) || instances end

      while queue_head && events[queue_head]
        # puts "\nload next overlaps\n"
        load_next_overlaps(queue_head, events, time_mark)
# byebug if @interrupt # view instances before next calls
        time_mark =
        call_overlap_test(
          [ @overlap_set.first, start_time: time_mark ],
          @overlap_set.second,
          instances: instances_proc )
        queue_head =
        reset_queue_head(queue_head, events, time_mark)
# byebug if period == 4
      end

      instances
    end
    .flatten(1)
  end #form_instances_by_events

  def load_next_overlaps(queue_head, events, time_mark)
    # byebug if @interrupt
    queue_tail =
    events.index(@overlap_set.last) if @overlap_set
    @overlap_set = []
    # while accommodates no-duration shift errors in API data
    while events[queue_head].start_time == events[queue_head].end_time
      queue_head += 1 end

    events[queue_head..-1]
    .each_with_index do |comparison, i|
      if events[queue_head].end_time > comparison.start_time &&
      # time_mark used as 'end time of last instance', to exclude already-processed, prior temporally-ordered events
      time_mark < comparison.end_time
        @overlap_set.push comparison
      else
        unless queue_tail &&
          (queue_head+i) < queue_tail then break end
      end
      # byebug if @interrupt # populating @overlap_set
    end
  end

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

  def reset_queue_head(queue_head, events, time_mark)
    # byebug if @interrupt
    if @overlap_set.any?
      queue_head =
      events.index(@overlap_set.first)
      # finished w/ @overlap_set; reset prior to next load
    else
      # set queue_head to the next event that starts by the time_mark
      queue_event =
      events[queue_head..-1]
      .find do |event|
        time_mark <= event.start_time end
      queue_head = events.index(queue_event)
    end
  end

  def overlap_test( basis, comparison, instances: )
    # byebug if basis == nil
    n = @overlap_set.index(basis[:event])
    min_by_et = Proc.new do
      @overlap_set.min_by(&:end_time) end
    # 'queue-head' in @overlap_set at last shift-- (1/4)
    if comparison == nil
      # only one player on ice (5v3s)-- (1/3)
        # collect, return set end time
      if basis[:event] == @overlap_set.first
        instances.call(
          Hash[
            events: @overlap_set.clone,
            end_time: (end_time = basis[:end_time]),
            start_time: basis[:start_time] ] )
        @overlap_set = []
        return end_time
      # 'queue_head' event demarcates last instance in set-- (2/3)
        # collect, delete, return @overlap_set end time
      elsif min_by_et.call.end_time == (end_time = @overlap_set.first.end_time)
      # (condition): first event ends first
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: min_by_et.call.end_time ] )
        @overlap_set
        .delete_if do |event|
          event.end_time == end_time end
        return end_time
      # next instance (commonly for intervening instances)-- (3/3)
        # collect, delete, call
      else
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: (end_time = min_by_et.call.end_time) ] )
        @overlap_set
        .delete_if do |event|
          event.end_time == end_time end
        call_overlap_test(
          [ @overlap_set.first, start_time: end_time ],
          @overlap_set.second,
          instances: instances )
      end
    # start time of overlap set or instance-- (2/4)
      # increment 'queue-head'
    elsif basis[:start_time] >= comparison[:start_time]
    # notes: comparison, at start of new frame, could precede basis
      call_overlap_test(
        [ comparison[:event], start_time: basis[:start_time] ],
        @overlap_set[n+2],
        instances: instances )
    #intervening start time-- (3/4)
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
    #end of instance-- (4/4)
    elsif (min_et = min_by_et.call).end_time <= comparison[:start_time]
      basis_i = @overlap_set.index( basis[:event] )
      # collect, delete, reset queue-head
      instances.call(
        Hash[
          events: @overlap_set[0..basis_i].clone,
          start_time: basis[:start_time],
          end_time: min_et.end_time ] )
      @overlap_set
      .delete_if do |event|
        event[:end_time] == min_et.end_time end
      call_overlap_test(
        [ @overlap_set.first, start_time: min_et.end_time ],
        @overlap_set.second,
        instances: instances )
    end
  end

  def group_by_players(instances_by_events_hashes)
    # {
      # [instances' player_id_nums] => [
        # { :events => [instance_by_events_1], :start_time => "00:00", :end_time => "00:01" }
        # { :events => [instance_by_events_5], :start_time => "00:20", :end_time => "00:23" }
    # ] }
    units_groups_hash =
    instances_by_events_hashes
    .group_by do |inst_hash|
      inst_hash[:events]
      .map do |event|
        event.player_id_num end.sort
    end
  end #group_by_players


 # ////////////////////  create_units_and_instances helpers /////////////#

  def find_or_create_units (formed_units)
    new_formed_units, units_records_queue = get_preexisting_units(formed_units)

    # nils stand for new units [absent from records]
    if units_records_queue.any? nil
      units_queue =
      insert_units(
        new_formed_units,
        (@units_records_queue = units_records_queue).clone )
      units_queue
    else units_records_queue end
  end

  def get_preexisting_units (formed_units)
    new_formed_units = formed_units.clone
    # nils act as placeholders for queued new units. swaps pre-existing units with their records from db.
    puts "\n\n #get_preexisting_units #{formed_units.map(&:size)} \n\n"

    units_records_queue =
    formed_units
    .map do |unit|
      # bind_targets = []
      # binds =
      # unit.map.with_index do |value, index|
      #   bind_targets.push("$#{index + 1}")
      #   assemble_binds("player_id_num", value) end

# performance: use the 'u_cir_pro' view for the joins?
      unit_record =
      Unit
      .select(:id)
      .joins(circumstances: [player_profile: [:player]])
      .where(players: {player_id_num: unit })
      .group(:id)
      .having('COUNT(players.player_id_num) = ?', unit.size)[0]

      # ApplicationRecord.connection.exec_query(
      #   retrieve_unit_sql(bind_targets),
      #   "SQL",
      #   binds ).rows.first
      if (unit_record)
        new_formed_units
        .delete_at(new_formed_units.index(unit)) end
      unit_record
    end #map

    puts "\n\n get_preexisting_units done \n\n"

    [new_formed_units, units_records_queue]
  end

  def insert_units(formed_units, records_queue)
    inserted_units = []
    prepared_units =
    formed_units.
    map do |unit|
      Hash[
        created_at: Time.now,
        updated_at: Time.now ]
    end
    units_changes =
    SQLOperations.sql_insert_all("units", prepared_units).count

    if units_changes > 0
      inserted_units =
      Unit.order(id: :desc).limit(units_changes)
# performance:
  # collect-then-insert rewrite—— just track the IDs [and persist safely in redis] before writing to DB?
    end

    # replaces queue nils with the freshly inserted units
    inserted_units.reverse
    .each do |record|
      nil_i = records_queue.index(nil)
      if nil_i
        records_queue[nil_i] = record end
      end if inserted_units.any?

    records_queue
  end

  def create_instances_and_circumstances(queued_units, units_groups_values)
    # penalty_data = get_special_teams_api_data()
    # penalities = add_penalty_end_times(penalty_data)
    # made_instances = add_penalty_data_to_instances(units_groups, penalties)
    create_circumstances(queued_units, units_groups_values) if @units_records_queue

    prepped_insts_grps =
    prepare_instances(queued_units, units_groups_values)
    queued_instances =
    insert_instances(prepped_insts_grps.flatten)
  end

  def prepare_instances (queued_units, units_groups)
    prepared_instances_groups =
    queued_units
    .map.with_index do |unit, i|
      # (create_units already reverses queued_units)
      # coincident index from source: units_groups_hash
      units_groups[i]
      .map do |inst|
        Hash[
          unit_id: unit.id,
          start_time: inst[:start_time],
          duration: TimeOperation.new(:-, [ inst[:end_time], inst[:start_time] ]).result,
          # penalty: ( inst[:penalty] || false ),
          created_at: Time.now,
          updated_at: Time.now ] # *3
      end
    end
  end #prepare_instances

  def insert_instances(prepared_instances)
    instances_changes = SQLOperations.sql_insert_all("instances", prepared_instances).count

    queued_instances =
    Instance.order(id: :desc).limit(instances_changes).reverse
  end

  def create_circumstances(queued_units, units_groups_values)
    new_units_groups = units_groups_values.clone

    # delete unit group, if unit preexisted as retrieved into @units_records_queue;
    # collect the new unit otherwise.
    new_units_queue =
    @units_records_queue
    .map.with_index do |record, i|
      if record.class == Unit
        new_units_groups[i] = nil
      else
        queued_units[i] end
    end.compact
    @units_records_queue = nil

    # store the specific profile (includes position), for this unit
    prepared_circumstances = []
    new_units_groups.compact
    .each_with_index do |group, i|
      group[0][:events]
      .each do |evnt|
        # shift events only here
        prepared_circumstances +=
        evnt.player_profiles
        .map do |profile|
          Hash[
            unit_id: new_units_queue[i].id,
            player_profile_id: profile.id,
            created_at: Time.now,
            updated_at: Time.now ]
        end
      end #each evnt
    end #each group


    SQLOperations.sql_insert_all("circumstances", prepared_circumstances)
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

  def associate_roster_to_units(queued_units, roster)
    puts "\n\n associate_roster_to_units \n\n"

# performance: single query for units' rosters matching roster instead?
    queued_units_new_roster =
    Unit.where(id: queued_units)
    .preload(:rosters)
    .reject do |unit|
      unit.rosters.include? roster end

    prepared_rosters_units =
    queued_units_new_roster
    .map do |unit|
      Hash[
        roster_id: roster.id,
        unit_id: unit.id ]
    end

    SQLOperations.sql_insert_all("rosters_units", prepared_rosters_units) if prepared_rosters_units.any?
  end




# //////////////////// helpers //////////////////// #

  #select subset of units, by team first? or by presence of all players

#refactor: use module?
  def retrieve_unit_sql (bind_targets)
    <<~SQL
      SELECT units.id
      FROM units
      JOIN
        (SELECT unit_id
        FROM instances
        JOIN events_instances
        ON instance_id = instances.id
        JOIN events
        ON events.id = event_id
        WHERE events_instances.instance_id IN
          (SELECT instance_id
          FROM events_instances
          WHERE event_id IN
            (SELECT id
            FROM events
            WHERE player_id_num IN (#{bind_targets.join(', ')})
              AND events.event_type = 'shift' )
          GROUP BY instance_id
          HAVING COUNT(*) >= #{bind_targets.size} )
        AND events.event_type = 'shift'
        GROUP BY unit_id, instance_id
        HAVING COUNT(instance_id) = #{bind_targets.size} ) AS u_ids
      ON units.id = u_ids.unit_id
      GROUP BY units.id
    SQL
  end

  def assemble_binds(field, value)
    ActiveRecord::Relation::QueryAttribute.new(field, value, ActiveRecord::Type::Integer.new)
  end



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

# *7- (refactor)
# - put method in library file

# *8- live-update: (NOT offered in API)
# assuming API lists [shift] events only after they 'complete'—
  # 'patch' event arrays, by redoing all prior instances which should include (overlap) new shift events
# else—
  # only need to patch [new events] into the last instance

# ///////////// extra ///////////// #



# =end

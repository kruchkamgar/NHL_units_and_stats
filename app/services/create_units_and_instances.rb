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
    2 => ["Forward"], #4-on-4 (EVGs), SH
    3 => ["Forward"],
    5 => ["Forward", "Defenseman"],
    # 6 => ["Forward", "Defenseman", "Goalie"], #6-skater
  }

  def create_records_from_shifts (team, roster, game, units)
    @team, @units_includes_events = team, units
    @game = Game.where(id: game).includes(events: [:player_profiles])[0]
    @roster = Roster.where(id: roster).includes(:players)[0]

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|
      roster_sample = get_roster_sample (unit_type)
      #find the shifts matching the roster sample
      shifts = get_shifts(roster_sample)
      # sort shifts by start time, for each period
      # {[period1 event1, 2...], [p2 event1, 2, ...] ... }
      period_chronology = shifts_into_periods (shifts)
      #find all unit instances by shift events' temporal overlaps (format: array of arrays)
      instances_of_events_arrays = form_instances_of_events(period_chronology, unit_size)
      units_groups_hash = group_by_players(instances_of_events_arrays)

      create_units_and_instances (units_groups_hash)
    end

    @units_includes_events
  end #create_records_from_shifts

  def create_units_and_instances (units_groups_hash)
    units_records =
    find_or_create_units(units_groups_hash.keys)

    instances_records =
    create_instances(units_records, units_groups_hash.values)

    associate_events_to_instances(instances_records, units_groups_hash.values.flatten(1))

    @units_includes_events +=
    ( @inserted_units.includes( instances: [ :events ]).
    where(instances: {events: {event_type: "shift"}}).to_a - @units_includes_events ) if @inserted_units
  end

  def find_or_create_units (units)
    formed_units, ordered_unit_array = get_preexisting_units(units)

    # nils stand for new units [absent from records]
    if ordered_unit_array.any? nil
      ordered_unit_array =
      insert_units(formed_units, ordered_unit_array)
    else ordered_unit_array end
  end

  def insert_units(formed_units, ordered_unit_array)
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
    @inserted_units.reverse.
    each do |unit|
      nil_ind = ordered_unit_array.index(nil)
      if nil_ind
        ordered_unit_array[nil_ind] = unit end
      end #if inserted_units.any?

    ordered_unit_array
  end

  # performance: store [loaded] units for team in instance variable
  def get_preexisting_units (units)
    # @existing_units =
    # Unit.includes( instances: [ :events ]).
    # where(instances: {events: {event_type: "shift"}})
    formed_units = units.clone
    # nils act as placeholders for queued new units. swaps pre-existing units with their records from db.
    ex_and_formed_u_nils =
    units.
    map do |unit|
      existing_unit =
      @units_includes_events.
      select do |ex_unit|
        if ex_unit.instances.first.events.map(&:player_id_num).sort == unit.sort
          # byebug if unit.sort == [8471233, 8475151, 8475791]
          formed_units.delete_at(formed_units.index(unit))
          true
        end
      end
      existing_unit.first unless existing_unit.empty?
    end

    [formed_units, ex_and_formed_u_nils]
  end

  def create_instances (inserted_units, units_groups)
    #  input units ids into each of instances hashes array
    # insert units; get units; ...

    prepared_instances =
    inserted_units. #create_units already reverses them
    map.with_index do |unit, i|
      units_groups[i]. # coincident index from source: units_grouped_instances
      map do |instance| # [ event1, event2, ... ]
        Hash[
          unit_id: unit.id,
          start_time: (start_time = instance.max_by(&:start_time).start_time ),
          duration: TimeOperation.new(:-, start_time, instance.min_by(&:end_time).end_time).result,
          created_at: Time.now,
          updated_at: Time.now ]
      end # *3
    end.flatten(1)

    instances_changes = SQLOperations.sql_insert_all("instances", prepared_instances)

    inserted_instances =
    Instance.order(id: :desc).limit(instances_changes).reverse
  end

  def associate_events_to_instances(inserted_instances, formed_instances)
    # insert instances; get instances; ...
    prepared_associations =
    inserted_instances.
    map.with_index do |instance, i|
      formed_instances[i].map do |event|
        # byebug if formed_instances[i].to_a.
        # map(&:player_id_num).sort == [8471233, 8475151, 8475791]
        Hash[
          instance_id: instance.id,
          event_id: event.id
        ]
      end
    end.flatten

    SQLOperations.sql_insert_all("events_instances", prepared_associations)
  end


  # ////////////////// prep methods ////////////////// #

  # filter to get certain player types (see UNIT_HASH)
  def get_roster_sample (player_types)
    roster_sample =
    @roster.players.
    select do |player|
      player_types.
      include? (
        @game.player_profiles.
        find do |profile|
        profile.player_id == player.id end.
        position_type
      )
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
    shift_events.
    group_by do |event|
      event.period end.
    each do |period, events|
      events.
      sort_by! do |shft|
        [shft.start_time, shft.end_time] end
    end
  end #shifts_into_periods

  # FILTER NON-SHIFT EVENTS?
  def form_instances_of_events (p_chron, unit_size) # *4

                    #detect number of players on ice (3, 4 (SH), 5, 6-skaters)

  # ? suspect logic
    # exclude power-plays by detecting 4-fwds on ice
      # - do the 5-man units first; (reject 4-fwds)
    # - on 3-man, reject when concurrent with 4-fwds
    # look for the goalie changes and derive new instances from 5-man units.


    #[only] 2 man overlaps (not more)
=begin
    # if 2nd (n+1) overlap, overlaps 1st with a later start time,
      # 1st comparison
         then use the second overlap's start time as the instance end time.
      # 2nd comparison
          if 1st overlap has an earlier end time than both 2nd and basis, then use 1st's end time [and basis end time] for instance bounds [of 2nd and basis].
      if...

      find next event after last comparison.
        # overlaps.max_by end time; index(last comparison) + 1


        #
        # instances =
        # overlaps.
        # combination(unit_size-1).to_a.
        # map do |combination|
        #   instance =
        #   [event, *combination].sort do |a,b|
        #     a.start_time <=> b.start_time end
        #   instance if mutual_overlap(instance)
        # end.compact
=end
    # p_chron.
    # map do |period, events|
    #   queue_head = 0
    #   while events[queue_head]
    #     overlaps = []
    #     for comparison in events[queue_head..-1]
    #       if event.end_time > comparison.start_time
    #         overlaps.push comparison
    #       else break overlaps end
    #     end
        # overlaps.sort_by do |event| [event, event] end

    p_chron.
    map do |period, events|
      # call overlaps(events.first)
      end_time = nil; queue_head = 0
      instances = []
      while events[queue_head]
        load_next_frame(queue_head, events, end_time)
        instances_proc = Proc.new do |inst|
          (instances.push inst if inst) || instances end
        end_time =
        call_overlap_test(
          [ @overlap_set.first, start_time: end_time ],
          @overlap_set.second,
          instances: instances_proc )
        byebug
        queue_head =
        reset_queue_head(queue_head, events, end_time)
      end
      # end.reject(&:empty?).flatten(1)
    end.flatten(1)
  end #form_instances_of_events

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

  def load_next_frame(queue_head, events, end_time = nil)
    @overlap_set = []
    for comparison in events[queue_head..-1]
      if events[queue_head].end_time > comparison.start_time
        @overlap_set.push comparison
      end
    end # for
    # byebug
  end

  def reset_queue_head(queue_head, events, end_time)
    if @overlap_set.any?
      queue_head =
      events.index(@overlap_set.first)
    else
      queue_event =
      events[queue_head..-1].
      find do |event|
        end_time <= event.start_time end
      queue_head = events.index(queue_event)
    end
  end

  def overlap_test( basis, comparison, instances: )
    n = @overlap_set.index(basis[:event])
    min_by_et = Proc.new do
      @overlap_set.min_by(&:end_time) end

    if comparison == nil
      if basis[:event] == @overlap_set.first
        return "wtf?"
      elsif min_by_et.call.end_time == (end_time = @overlap_set.first.end_time) # last frame
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: min_by_et.call.end_time ] )
        @overlap_set.
        delete_if do |event|
          event.end_time == end_time end
        return end_time
      else #next frame
        byebug
        byebug if @overlap_set.size ==1
        instances.call(
          Hash[
            events: @overlap_set.clone,
            start_time: basis[:start_time],
            end_time: min_by_et.call.end_time ] )
        call_overlap_test(
          [ @overlap_set.first, start_time: min_by_et.call.end_time ],
          @overlap_set.second,
          instances: instances )
      end
    elsif basis[:start_time] >= comparison[:start_time] #comparison, at start of new frame, could precede basis
    # increment--
      call_overlap_test(
        [ comparison[:event], start_time: basis[:start_time] ],
        @overlap_set[n+2],
        instances: instances )
    elsif basis[:start_time] < comparison[:start_time] && comparison[:start_time] < min_by_et.call.end_time
    # call, increment--
      basis_i = @overlap_set.index(basis[:event])
      byebug if @overlap_set[0..basis_i].size ==1
      instances.call(
        Hash[
          events: @overlap_set[0..basis_i].clone,
          start_time: basis[:start_time],
          end_time: comparison[:start_time] ] )
      # comparison becomes new basis
      call_overlap_test(
        comparison[:event],
        @overlap_set[n+2],
        instances: instances ) # if n+2
       # if min_by_et.call< "20:00"
    elsif (min_et = min_by_et.call).end_time <= comparison[:start_time] #min_by_et != initial [ or else this would evaluate false, per overlap.push criteria]
      basis_i = @overlap_set.index( basis[:event] )
      byebug if @overlap_set[0..basis_i].size ==1
      instances.call(
        Hash[
          events: @overlap_set[0..basis_i].clone,
          start_time: basis[:start_time],
          end_time: min_et.end_time ] )
      @overlap_set.delete_at( @overlap_set.index(min_et) )
      call_overlap_test(
        [ @overlap_set.first, start_time: min_et.end_time ],
        @overlap_set.second,
        instances: instances )
    end

  end

  def mutual_overlap (shift_group)
    # refine: set minimum ice-time shared
    shifts_array = shift_group.clone

    # overlap defined: shift ends after its comparison starts
    #...without starting after the comparison shift ends
    shifts_array.
    map.with_index do |shift, i|
      shifts_array[(i+1)..-1].# +1 past index of "shift"
      all? do |comparison|
        shift.end_time > comparison.start_time && comparison.end_time > shift.start_time
      end if i < shifts_array.size - 1
    end.compact.all?
  end #mutual_overlap

  def group_by_players(instances_of_events_arrays)
    # [  [instance_of_events 1], [...2], [...3]  ]
    if instances_of_events_arrays
      @existing_game_instances = Instance.includes("events").where( events: { game_id: @game.id })

      # subtract events of existing game instances
      @formed_instances_of_events = instances_of_events_arrays - @existing_game_instances.map(&:events)
    end

    # {
      # [instance1 player_id_nums] =>
      # [ [instance_of_events 1], [...2] ]  }
    units_groups_hash =
    @formed_instances_of_events.
    group_by do |events|
      events.
      map do |event|
        event.player_id_num end.sort
    end
  end #group_by_players

  module_function :create_records_from_shifts,
   :get_roster_sample,
   :get_shifts,
   :form_instances_of_events,
   :make_event_hash,
   :load_next_frame,
   :reset_queue_head,
   :call_overlap_test,
   :overlap_test,
   :shifts_into_periods,
   :mutual_overlap,
   :group_by_players,
   :get_preexisting_units,
   :insert_units,
   :create_instances,
   :find_or_create_units,
   :create_units_and_instances, :associate_events_to_instances

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
#  add an event into an instance_of_events array

  # integration means only tally +/- per game rather than for each team

#
# *5- (pattern)
# situation: if doing a live-update, one may need to update new instances for a unit
# - could use a different API for this however (w/ similar code)
# create instances for new instances_of_events only
#

# *6-
# (requirements)
# unit criteria– why no larger minimum overlap time?
#   - even a 2-second overlap can form a difference in the play (relevant unit criteria)

#   -? if using minimum overlap time, use on top of 2 or 4 plyrs (3, or 5-man unit)

# ///////////// extra ///////////// #



# =end

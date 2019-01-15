=begin
-- TODO -- add units-rosters relationship? (alt. find by roster players for Units' shift-events only)

- get shifts by team, for a game
- create instances [of units], by processing shifts

- process the special events, tallying results to instances fields
=end



module CreateUnitsAndInstances
  include Utilities # time calculations

  UNIT_HASH = {
    # 2 => ["Defenseman"]
    3 => ["Forward"],
    5 => ["Forward", "Defenseman"],
    6 => ["Forward", "Defenseman", "Goalie"]
  }

  def create_records_from_shifts (team, roster, game)

    @team = team
    @game = Game.where(id: game).includes(events: [:player_profiles])[0]
    @roster = Roster.where(id: roster).includes(:players)[0]

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|

      roster_sample = get_roster_sample (unit_type)

      #find the shifts matching the roster sample
      shifts = get_shifts(roster_sample)

      # sort shifts by start time, for each period
      period_chronology = shifts_into_periods (shifts) # {[period1 shifts], [period 2 shifts] ...}

      #find all unit instances by shift events' temporal overlaps (format: array of arrays)
      instances_events_arrays = make_instances_events(period_chronology, unit_size)
# performance: group instances_events from all periods before calling 'create'
      units_groups_hash = group_by_players(instances_events_arrays)

      make_units_and_instances (units_groups_hash)
    end
  end #get_units_from_shifts

  def make_units_and_instances units_groups_hash

    inserted_units =
    create_units(units_groups_hash.keys)
    inserted_instances = create_instances(inserted_units, units_groups_hash.values)

    associate_events_to_instances(inserted_instances, units_groups_hash.values.flatten(1))
  end

  def get_preexisting_units (units)
    @existing_units = Unit.includes( instances: [ :events ])
    ex_units_and_nils =
    units.
    map do |unit|
      existing_unit =
      @existing_units.
      select do |ex_unit|
        ex_unit.instances.first.events.
        map(&:player_id_num).sort == unit.sort end
      existing_unit.first unless existing_unit.empty?
    end
  end

  def create_units (units) #instances_events_arrays, changes
    ex_units_and_nils =
    get_preexisting_units(units)
    made_units =
    units.map do |unit|
      Hash[
        created_at: Time.now,
        updated_at: Time.now ] end
    units_changes =
    SQLOperations.sql_insert_all("units", made_units)
    inserted_units =
    Unit.order(id: :desc).limit(units_changes)

    ex_units_and_nils.zip(inserted_units).flatten.compact
  end

  def create_instances (inserted_units, units_groups)
    #  input units ids into each of instances hashes array
    # insert units; get units; ...

    made_instances =
    inserted_units.reverse.
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

    instances_changes = SQLOperations.sql_insert_all("instances", made_instances)

    inserted_instances = Instance.order(id: :desc).limit(instances_changes)
  end

  def associate_events_to_instances(inserted_instances, new_instances)
    # insert instances; get instances; ...
    made_associations =
    inserted_instances.reverse.
    map.with_index do |instance, i|
      new_instances[i].map do |event|
        Hash[
          instance_id: instance.id,
          event_id: event.id
        ]
      end
    end.flatten

    SQLOperations.sql_insert_all("events_instances", made_associations)
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

  # get the shifts for the roster
  def get_shifts roster_sample
    # any player in the roster match each shift event's player profile(s)?
    shifts = @game.events.
    select do |event|
      roster_sample.
      any? do |player|
          event.player_profiles.
          any? do |profile|
            profile.player_id == player.id end
      end
    end
  end #get_shifts

  def shifts_into_periods (shift_events)
    period_chron =
    shift_events.group_by do |event|
      event.period end.
    each do |period, events|
      events.sort! do |shft_a, shft_b|
        shft_a.start_time <=> shft_b.start_time end
    end

  end #shifts_into_periods


  def make_instances_events (p_chron, unit_size) # *4

    # currently also acts to filter non-shift events
    min_shift_length = "00:15" # __ perhaps use a std deviation from median shift length
    p_chron.
    map do |period, events|
      events.delete_if do |event|
        event.duration <= min_shift_length end
      events.
      select.with_index do |shift, i|
        iteration = ( i...(i+unit_size) )
        mutual_overlap ( events[iteration] )
      end
    end
  end #make_instances_events

  def mutual_overlap (shift_group)
    # refine: set minimum ice-time shared
    shifts_array = shift_group.clone
=begin (comments)

unit criteria– why no larger minimum overlap time?
  - even a 2-second overlap can make a difference in the play (relevant unit criteria)
  - if using minimum overlap time, use on top of 2 or 4 plyrs (3, or 5-man unit)
=end

# overlap defined: shift ends after its comparison starts
#...without starting after the comparison shift ends
    shifts_array.
    map.with_index do |shift, i|
      shifts_array[(i+1)..-1].# +1 past index of "shift"
      all? do |overlaps|
        shift.end_time > overlaps.start_time && overlaps.end_time > shift.start_time
      end if i < shifts_array.size - 1
    end.compact.all?
  end #mutual_overlap

  def group_by_players(instances_events_arrays)
    # [  [instance_events 1], [...2], [...3]  ]
    if instances_events_arrays
      @existing_game_instances = Instance.includes("events").where( events: { game_id: @game.id })

      # subtract events of existing game instances
      @new_instances_events = instances_events_arrays - @existing_game_instances.map(&:events)
    end

    # {
      # [instance1 player_id_nums] =>
      # [ [instance_events 1], [...2] ]  }
    units_groups_hash =
    @new_instances_events.
    group_by do |events|
      events.
      map do |event|
        event.player_id_num end.sort
    end
  end #group_by_players

  module_function :create_records_from_shifts,
   :process_special_events,
   :get_roster_sample,
   :get_shifts,
   :make_instances_events,
   :shifts_into_periods,
   :mutual_overlap,
   :group_by_players,
   :get_preexisting_units,
   :create_instances,
   :create_units,
   :make_units_and_instances, :associate_events_to_instances
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
#  add an event into an instance_events array

  # integration means only tally +/- per game rather than for each team

#
# *5- (pattern)
# situation: if doing a live-update, one may need to update new instances for a unit
# - could use a different API for this however (w/ similar code)
# create instances for new instances_events only
#

# ///////////// extra ///////////// #



# =end

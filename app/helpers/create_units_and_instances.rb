=begin
- get shifts by team, for a game

=end



module CreateUnitsAndInstances
  include Utilities # time calculations

  UNIT_HASH = {
    3 => ["Forward"],
    5 => ["Forward", "Defenseman"],
    6 => ["Forward", "Defenseman", "Goalie"]
  }

  def get_lines_from_shifts (team, roster, game)

    @team, @roster, @game = team, roster, game

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|

      roster_sample = get_roster_sample (unit_type)
      shifts = get_shifts(roster_sample) #find the shifts matching the roster sample
      period_chronology = shifts_into_periods (shifts)

      #find all unit instances by shift events' temporal overlaps (format: array of arrays)
      instances_events = make_units_events(period_chronology, unit_size)

      create_instances (instances_events)
    end

  end

  def create_instances instances_events
    @existing_units = Unit.includes( instances: [ :events ])

    if instances_events
      @existing_game_instances = Instance.includes("events").where( events: { game_id: "#{@game.id}"})

      # subtract events of existing game instances
      new_instances_events = instances_events - @existing_game_instances.map(&:events)
    end


    new_unit_instances_array = []
    new_instances_array = []
    prior_selected_unit_instances = []
    # [[event1, event2, ...], [instance2's events]]
    unless new_instances_events.empty? then new_instances_events.each do |events|
      next if prior_selected_instances.include? events

      # select all like instances, to add to a unit
      new_unit_instances = instances_events.select { |match|
        events.map(&:player_id_num).sort == match.map(&:player_id_num).sort # *2.nui
      }

      new_unit_instances_array += new_unit_instances
      # *5
      # only create a unit if one had not existed prior
      unit = @existing_units.find { |unit|
        unit.instances.map(&:events) & events
      }
      new_unit = Unit.create unless unit

      new_instances_array += new_unit_instances.map { |event_array|
        # event_array.each { |event|
        #   #event.instance_id = new_instance.id
        #   new_instance.events << event
        # }
        Hash[
          unit_id: new_unit.id || unit.id,
          start_time: (start_time = event_array.max_by(&:start_time).start_time ),
          duration: TimeOperation.new(:-, start_time, event_array.min_by(&:end_time).end_time).result
        ] # *3
      }

      prior_selected_instances += new_unit_instances
    end # instances_events.each...

    instances_changes = insert_instances(new_instances_array)
    associate_events_to_instances(new_instances_array, instances_changes)

  end


  def insert_instances (instances_array)
    SQLOperations.sql_insert_all("instances", instances_array)
  end

  def associate_events_to_instances (instances_events_arrays, changes)
    inserted_instances = Instance.order(id: :desc).limit(changes)

    new_associations_array = inserted_instances.map do
    |instance|
        # find events array, which formed basis for [inserted] instance
        instances_events_array.find{ |events_array|
          (events_array - instance.map(&:events)).empty?
        }.map { |event|
          # an "events_instances" record per event
          Hash[
            instance_id: instance.id,
            event_id: event.id
          ]
        }
      end.flatten

    SQLOperations.sql_insert_all("events_instances", new_associations_array)
  end
# private


  def process_special_events (team, roster, game)
    @team, @roster, @game = team, roster, game

    special_events = Event.includes( :log_entries).where("events.event_type != 'shift' AND events.game_id = '#{@game.id}'").references(:log_entries)

    opposing_team_events = special_events.select { |event|
        @roster.players.any? { |player|
          player.player_id == event.player_id_num
        }
        # @roster.players.any? {|player| event.player_profiles.include? player.player_profile}
      } # or

    # add the events and their tallies for each instance
    special_events.each do |event|
        game_instances = Instance.includes("events").where(events: { game_id: "#{@game.id}"})

        cspdg_instance = game_instances.find { |instance|
          instance_end_time = TimeOperation.new(:+, instance.start_time, instance.duration).result
          # byebug if instance.id == 8392 && event.end_time == "19:32"
          event.end_time > instance.start_time && event.end_time <= instance_end_time && instance.events.first.period == event.period
        }

        next unless cspdg_instance
        event.instances << cspdg_instance

        # event_log = Event.includes("log_entries").where(log_entries: { event: event })
        event.log_entries.each { |entry|
          if opposing_team_events.any? { |event|
            event.log_entries.include? entry
          }
            case entry.event.event_type
            when "EVG", "SHG"
              cspdg_instance.plus_minus ||= 0
              cspdg_instance.plus_minus -= 1 if entry.action_type == "goal"; cspdg_instance.save
            end
          else
            case entry.action_type
            when "assist", "primary", "secondary"
              cspdg_instance.assists ||= 0; cspdg_instance.assists += 1
            when "goal"
              cspdg_instance.goals ||= 0; cspdg_instance.goals += 1
            end
            cspdg_instance.save
          end
        }
    end
  end

  # get only certain types of players (see UNIT_HASH)
  def get_roster_sample (player_types)

    roster_sample = @roster.players.select { |player|
      player_types.include? (
        @game.player_profiles.find { |profile|
         profile.player_id == player.id
        }.position_type
      )
    }
  end

  # get the shifts for the roster
  def get_shifts roster_sample
    # any player in the roster match each shift event's player profile(s)?
    game_events = @game.events #single load for performance
    shifts = game_events.select { |event|
        roster_sample.any? { |player|
            event.player_profiles.any? {|profile|
              profile.player_id == player.id
            }
        }
      }
  end

  def shifts_into_periods (shift_events)
    period_chron = {1 => nil, 2 => nil, 3 => nil}

    period_chron.each { |period, v|

      period_chron[period] = shift_events.select { |event|
        event.period == period
      }.sort { |shft_a, shft_b|
        shft_a.start_time <=> shft_b.start_time
      }
    }
    period_chron
  end

  def make_units_events (p_chron, unit_size)
    minimum_shift_length = "00:15" # __ perhaps use a std deviation from median shift length

    instances_events = []
    p_chron.each { |period|
      i=0; period_shifts = period[1]

=begin (rewrite)
      period_shifts.each_with_index do |shift, i|
        next unless shift.duration > minimum_shift_length
          period_shifts[i...(i+unit_size)]
          ...test mutual overlap
=end
      while i < (period_shifts.length-1)
        if period_shifts[i].duration == nil then byebug end
        if period_shifts[i].duration > minimum_shift_length
          shift = period_shifts[i..-1].first(unit_size)
          if mutual_overlap (shift)
            instances_events << shift
          end
        end
        i+=1
      end
    }
    instances_events
  end

  def mutual_overlap (shift_group)
    # refine: set minimum ice-time shared
    shifts_array = shift_group.clone
    overlap_test = []

    #make comparisons in a factorial-fashion pattern
=begin (rewrite)
  shifts_array.each_with_index { |shift, i|
    shifts_array[(i+1)..-1].all? { |overlaps?|
      shift.end_time > overlaps?.start_time && shift.start_time < overlaps?.end_time
    } if i < shifts_array.size - 1
  }

unit criteria– why no larger minimum overlap time?
  - even a 2-second overlap can make a difference in the play (relevant unit criteria)
  - if using minimum overlap time, use on top of 2 or 4 plyrs (3, or 5-man unit)
=end
    while shifts_array.length > 1
      base_shift = shifts_array.shift
      overlap_test << shifts_array.all? { |shift|
          #shift overlap definition:
          #shift ends after base shift starts
          #...without starting after base shift ends
          base_shift.end_time > shift.start_time && base_shift.start_time < shift.end_time
      }
    end

    overlap_test.all? #all true values in array? #{ |iteration| iteration }
  end

  module_function :get_lines_from_shifts, :process_special_events
end

=begin

*1—
instance.events.map { |event| event.log_entries.where(action_type: "shift").player_profile_id) }.sort.
  --re: player_id_num

instance.events.map { |event| event.log_entries.map(&:player_profile_id) }.flatten.uniq.sort

*2-
processing special events and shift events in same flow / methods

  nui-
  note: simply remove the NON-SHIFT / special events (with .compact?) for this step, if temporally processing all events together

*3-
instance start times derive, from the start of the overlap among all the involved players' shifts
duration measures the time spanned in this overlap

*4-
# process_special_events # no real need to do this separately from units_instances creation pipeline. integration could help tallying +/-

*5- (pattern)
situation: if doing a live-update, one may need to update new instances for a unit
- could use a different API for this however (w/ similar code)
create instances for new instances_events only

=end

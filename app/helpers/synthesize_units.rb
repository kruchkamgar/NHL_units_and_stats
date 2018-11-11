=begin
- get shifts by team

=end



module SynthesizeUnits

  UNIT_HASH = {
    3 => ["Forward"],
    5 => ["Forward", "Defenseman"],
    6 => ["Forward", "Defenseman", "Goalie"]
  }

  def self.get_lines_from_shifts (team, roster, game)

    @team, @roster, @game = team, roster, game

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|

      roster_sample = get_roster_sample (unit_type)

      #apply shifts to the roster units
      shifts = get_shifts(roster_sample) #find the shifts matching the roster sample
      period_chronology = shifts_into_periods (shifts)

      #find all unit instances by shift event temporal overlaps (array of arrays)
      instances_events = create_units_events(period_chronology, unit_size)

      # units_events.uniq { |unit|
      #   unit.events.map(&:player_id_num).sort #make unique based on this evaluation
      # }.each { |unit|
      #
      # }

      # [[event1, event2, ...], [instance2's events]]
      # cloned_instances = instances_events.clone
      instances_events.each do |instance|
        next if prior_selected_unit_instances.include? instance

        new_unit_instances = cloned_instances.select { |match?|
          # select all matching instances (having same players)
          instance.events.map(&:player_id_num).sort == match?.events.map(&:player_id_num).sort
        }

        new_unit = Unit.create
        new_unit_instances.each { |instance|
          new_instance = Instance.create(unit_id: new_unit.id)
          # add create_instance functionality
          instance.events.each { |event|
            event.instance_id = new_instance.id
          }
        }
        prior_selected_unit_instances += new_unit_instances.flatten
        # cloned_instances -= new_unit_instances

        # avoid duplication by deleting (or ignoring) current selection (new_unit_instances) from instances_events
        # may need to operate on a clone (clone.select...), within a .each on the original
      end


      @game_instances = []
      units_events.each { |instance|
        # build an instance
        @game_instances << create_instance(instance)

      # puts JSON.pretty_generate(JSON.parse(units.first(1).to_json))
      }

      # @game_instances.each { |instance|
      #   @game_instances.select { |inst|
      #     }
      #   instance.events.map(&:player_id_num).uniq.sort #*1
      # }.each { |unit| #unique based on player_profiles
      #     new_unit = Unit.new
      #     unit.each { |instance|
      #       instance.unit_id = new_unit.id
      #     }
      #     new_unit.save
      #   }
      #
      # @game_instances.uniq { |instance|
      #   instance.events.map(&:player_id_num).uniq.sort #*1
      # }.each { |unit| #unique based on player_profiles
      #     new_unit = Unit.new
      #     unit.each { |instance|
      #       instance.unit_id = new_unit.id
      #     }
      #     new_unit.save
      #   }

      process_special_events
    end
  end

# private

  def self.create_instance instance_events
    # assign new instance to each event set (shift).

    new_instance = Instance.find_or_create_by(
       start_time: instance_events.first.start_time, duration: instance_events.first.duration #instead find the overlap/intersect of its events
     )

    # add shift events to the new unit instance
    instance_events.each { |event|
      event.instance_id = new_instance.id
    }

    # # add special events
    # add_special_events(new_instance)

    new_instance
  end

  def self.process_special_events
    special_events = @game.events.where('event_type != "shift"')
    #opposing_team_evnets = special_events.each {|event|
    # @roster.players.any? {|player| event.player_profiles.include? player.player_profile}
    # } or @roster.player.any? player_id == event.player_id_num

    # add the events and their tallies for each instance
    @game_instances.each do |instance|
      special_events.select { |event|
        event.start_time == instance.start_time
      }.each { |event|
        event.instance_id = instance.id

        # case event.event_type
        # when "EVG", "PPG", "SHG"
        event.log_entries.each do |entry|
          case entry.action_type
          when "assist"
            instance.assists += 1
          when "goal"
            instance.goals +=1
            instance.plus_minus += 1
          end
        end
      }
    end

  end

  # then...
  # process score events and add to instances
  # calculate tallies [using model methods] and store them in instance.
    # get game instances into array
    # iterate over them and create units based on unique sets, comprised of players retrieved from their events —
    #(instances.map {|instance| instance.events.map(&:player_profile) }.uniq { |unit| unit.sort.first}


=begin
organize shifts into chronological order within an array*
    OR into hash with keys as the times, or shift number

    #LINE criteria: fwds' shifts starting prior and after a [reference] player's shifts
      - minimum overlapping duration [to avoid incidental/negligible shared ice-time]

=end


  def self.get_roster_sample (player_types)

    roster_sample = @roster.players.select { |player|
      player_types.include? (
        @game.player_profiles.find { |profile|
         profile.player_id == player.id
        }.position_type
      )
    }
  end

  def self.get_shifts roster_sample
    shifts = @game.events.select { |event|
      # any player in the roster match the shift event's player profile(s)?
        roster_sample.any? { |player|
            event.player_profiles.any? {|profile|
              profile.player_id == player.id
            }
        }
      }
  end

  def self.shifts_into_periods (shift_events)
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

  def self.create_units_events (p_chron, unit_size)
    minimum_shift_length = "00:15" # __ one std deviation from median shift length

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

  def self.mutual_overlap (shift_group)
    # refine: set minimum ice-time shared
    shifts_array = shift_group.clone
    overlap_test = []

    #make comparisons in a factorial-fashion pattern
=begin (rewrite)
  shifts_array.each_with_index { |shift|
    shifts_array[i..-1].all? { |overlaps?|
      shift.end_time > overlaps?.start_time && shift.start_time < overlaps?.end_time
    }
  }

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


end

=begin

*1—
instance.events.map { |event| event.log_entries.where(action_type: "shift").player_profile_id) }.sort.
  --re: player_id_num

instance.events.map { |event| event.log_entries.map(&:player_profile_id) }.flatten.uniq.sort

=end

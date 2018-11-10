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

      units_instances = create_units(period_chronology, unit_size)
      # units.uniq! { |unit| unit.sort.first } #sorts alphabetically and then makes uniq based on first item

      @game_instances = []
      units_instances.each { |instance|
        # build an instance
        @game_instances << create_instance(instance)

      # new_unit = Unit.new(
      # )
      #
      #   # build a circumstance
      #     # add a player
      # }

      # puts JSON.pretty_generate(JSON.parse(units.first(1).to_json))
      }

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
    # iterate over them and create units based on unique sets, of players retrieved from their events —
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

  def self.create_units (p_chron, unit_size)
    minimum_shift_length = "00:15" # __ one std deviation from median shift length

    units_instances = []
    p_chron.each { |period|
      i=0; period_shifts = period[1]
      while i < (period_shifts.length-1)
        if period_shifts[i].duration == nil then byebug end
        if period_shifts[i].duration > minimum_shift_length
          shift = period_shifts[i..-1].first(unit_size)
          if mutual_overlap (shift)
            units_instances << shift
          end
        end
        i+=1
      end
    }
    units_instances
  end

  def self.mutual_overlap (shift_group)
    # refine: set minimum ice-time shared
    shifts_array = shift_group.clone
    overlap_test = []
    while shifts_array.length > 1
      base_shift = shifts_array.shift
      overlap_test << shifts_array.all? { |shift|
          #shift overlap definition:
          #shift ends after base shift starts
          #...without starting after base shift ends
          base_shift.end_time > shift.start_time && base_shift.start_time < shift.end_time
      }
    end

    overlap_test.all? { |iteration| iteration }
  end



end

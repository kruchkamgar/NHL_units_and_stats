=begin
- get shifts by team

=end



module SynthesizeUnits

  UNIT_HASH = { 3 => ["Forward"] }
  UNIT_HASH[5] = ["Defenseman"] + UNIT_HASH[3]
  UNIT_HASH[6] = ["Goalie"] + UNIT_HASH[5]

  def self.get_lines_from_shifts (team, roster, game)
    @team, @roster, @game = team, roster, game

    # iterate through units: 6-man, 5-man, 3-man
    UNIT_HASH.each do |unit_size, unit_type|

      roster_sample = get_roster_sample (unit_type)

      #apply shifts to the roster units
      shifts = get_shifts(roster_sample) #find the shifts matching the roster sample
      period_chronology = shifts_into_periods (shifts)



      units = create_units(period_chronology, unit_size)
      units.uniq! { |unit| unit.sort.first }
      units.each { |unit|
        # build a unit
        # build a circumstance
          # add a player
      }
    end
    byebug
  end

# private

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
      #any shifts have player ID, matching with the roster?
        roster_sample.any? { |player|
            event.player_profiles.any? {|profile|
              profile.player_id == player.id
            }
        }
      }
      byebug
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
    byebug
  end

  def self.create_units (p_chron, unit_size)
    minimum_shift_length = "00:30" # __ one std deviation from median shift length

    units_instances = []
    p_chron.each { |period|
      i=0; period_shifts = period[1]
      while i < (period_shifts.length-1)
        if period_shifts[i].duration > minimum_shift_length
          byebug
          shift = period_shifts[i..-1].first(unit_size)
          if mutual_overlap(shift)
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
          base_shift["endTime"] > shift["startTime"] && base_shift["startTime"] < shift["endTime"]
      }
    end

    overlap_test.all? { |iteration| iteration }
  end



end

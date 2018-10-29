

module SynthesizeUnits

  def get_lines_from_shifts

    # puts JSON.pretty_generate(data)
    roster_sample = get_fwds_roster
    shifts = fwds_shift_events(roster_sample) #find the shifts matching the roster sample

    period_chron = shifts_into_periods (shifts)
    lines = get_lines (period_chron)
    lines.uniq! { |line| line.sort.first}
    lines.each { |unit|
      # build a unit
      # build a circumstance
        # add a player
    }
    byebug
  end

# private

=begin
organize shifts into chronological order within an array*
    OR into hash with keys as the times, or shift number

    #LINE criteria: fwds' shifts starting prior and after a [reference] player's shifts
      - minimum overlapping duration [to avoid incidental/negligible shared ice-time]

=end

  def get_shifts
    fwd_shifts = shift_events.select { |shift|
      #any shifts have player ID, matching with the roster?
        roster_hash.any? { |player|
            shift["playerId"] == roster_hash[player[0]]["person"]["id"]
        }
      }

  end

  def get_fwds_roster
    fwds_roster = Player.all.select { |player|
      player.position_type == "Forward"
    }
  end

  def shifts_into_periods (shift_events)
    period_chron = {1 => nil, 2 => nil, 3 => nil}

    period_chron.each { |period, v|

      period_chron[period] = shift_events.select { |event_h|
        event_h["duration"] && event_h["period"] == period  #make sure the events have a duration
      }.sort { |shft_a, shft_b|
        shft_a["startTime"] <=> shft_b["startTime"]
      }
    }

    period_chron
  end

  def get_lines p_chron
    minimum_shift_length = "00:30" # __ one std deviation from median shift length
    line_length = 3 # 5 possible fwds overlapping

    lines_instances = []
    p_chron.each { |period|
      i=0; period = period[1]
      while i < (period.length-1)
        if period[i]["duration"] > minimum_shift_length

          shift = period[i..-1].first(line_length)
          if mutual_overlap(shift)

            lines_instances << shift.map { |shift|
              shift["lastName"]
            }

          end
        end
        i+=1
      end
    }
    lines_instances
  end

  def mutual_overlap (shift_group)
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

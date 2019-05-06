# process special events per game, for one side

module ProcessSpecialEvents
  include Utilities
  include ComposedQueries

  def process_special_events

    get_special_events_data()
    # @special_events.reject do |event|
    #   event.event_type == "Shootout" end
    @team_events =
    @special_events - @opposing_events
    # team_sans_shg =
    # @team_events.reject do |event|
    #   event.event_type == "SHG" end
    opposing_sans_ppg =
    @opposing_events.reject do |event|
      event.event_type == "PPG" end # opposing PPG have no +/- impact

# only working for 3-man unit
    opposing_inst_event_data = assoc_special_events_to_instances(opposing_sans_ppg)
    team_inst_event_data =
    assoc_special_events_to_instances(@team_events)

    opposing_inst_event_data
    .each do |data|
      special_events_tally_logic(data) end
    team_inst_event_data
    .each do |data|
      special_events_tally_logic(data, true) end
  end

  def get_special_events_data

    @game_instances =
    instances_by_roster_and_game(@game.id, @roster.players.map(&:player_id_num))
    .eager_load(:events)

    @special_events = #*2
    Event.
    where( events: { game_id: @game.id } )
    .where.not(
      "events.event_type = ? OR events.event_type = ?", 'Shootout', 'shift' ).
    eager_load(:log_entries)

    # Player.arel_table.join(Roster.arel_table).on(Player.arel_table[:id]

    @opposing_events =
    @special_events.
    reject do |event|
      @roster.players.
      any? do |player|
        player.player_id_num == event.player_id_num end
    end
  end #get_special_events_data

  def assoc_special_events_to_instances (events)

    events
    .map do |event|
      # find the special event's corresponding instance
      cspg_instance =
      @game_instances.to_a
      .find do |instance|
        instance_end_time = TimeOperation.new(:+, instance.start_time, instance.duration).result

        event.end_time > instance.start_time && event.end_time <= instance_end_time && instance.events.first.period == event.period
      end
      byebug unless cspg_instance
      cspg_instance.events << event if (cspg_instance.events & [event]).empty? # adds even events by the OPPOSING team

      Hash[instance: cspg_instance, event: event]
    end

  end #assoc_special_events_to_instances

  def special_events_tally_logic (data, team_event=false)
    event = data[:event]; instance = data[:instance];
    delta = -1; # use default values for instances

    if team_event
      # aggregating individuals' points
      event.log_entries
      .each do |log_entry|
        case log_entry.action_type
        when "assist", "primary", "secondary"
          instance.assists ||= 0; instance.assists += 1
        when "goal"
          instance.goals ||= 0; instance.goals += 1
          delta = 1
        end end #each

      # special teams 'for' stats
      case event.event_type
      when "PPG"
        instance.ppg +=1
      when "SHG"
        instance.shg +=1
      end
    else
      # special teams 'against'
      case
      when "PPG"
        instance.ppga +=1
      when "SHG"
        instance.shga +=1
      end
    end

    # tally instance's plus_minus (both for and against)
    case event.event_type
    when "EVG", "SHG"
      instance.plus_minus ||= 0
      instance.plus_minus += delta
    end

    instance.save
  end #(method)

end


# *1-
# (improvement?)
#  process special events for a game instead of per team
#  add an event into an instance_events array within create_units_and_instances

  # integration means only tally +/- per game rather than for each team

# *2- spickermann says that I may enhance performance by performing the PPG filter-out with a SQL condition instead.
# Event.joins(player_profiles: {player: {rosters: :team}}).where(teams: {team_id: 1})
#
# --https://stackoverflow.com/questions/54471373/detect-and-find-return-nil-whereas-find-all-and-select-return-a-result

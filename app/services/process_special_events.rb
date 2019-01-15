module ProcessSpecialEvents
  include Utilities

  def process_special_events (team, roster, game)
    @team, @roster, @game = team, roster, game
    get_special_events_data

    @team_events = @special_events - @opposing_team_events

    opposing_data = associate_events_to_instances(@opposing_team_events)
    team_data =
    associate_events_to_instances(@team_events)

    tally_special_events(opposing_data)
    tally_special_events(team_data, true)
  end

  def get_special_events_data
    @game_instances =
    Instance.includes(:events).
    where(events: { game_id: @game.id})
    # add the events and their tallies for each instance

    @special_events =
    Event.includes(:log_entries).
    where(events: { game_id: @game.id } ).
    where.not(events: { event_type: 'shift'} )

    @opposing_team_events =
    @special_events.
    reject do |event|
      @roster.players.
      any? do |player|
        player.player_id == event.player_id_num end
    end
  end #get_special_events_data

  def associate_events_to_instances (events)
    events.
    map do |event|
      # find the special event's corresponding instance
      cspg_instance =
      game_instances.
      find do |instance| # *1
        instance_end_time =
        TimeOperation.new(:+, instance.start_time, instance.duration).result

        event.end_time > instance.start_time && event.end_time <= instance_end_time && instance.events.first.period == event.period
      end
      cspg_instance.events << event if (cspg_instance.events & [event]).empty?

      Hash[instance: cspg_instance, event: event]
    end

  end #associate_events_to_instances

  def tally_special_events (data, team_event=false)
    event = data[:event]; instance = data[:instance]
    instance.plus_minus ||= 0

    if team_event
      case event.log_entry.action_type
      when "assist", "primary", "secondary"
        instance.assists ||= 0; instance.assists += 1
      when "goal"
        instance.goals ||= 0; instance.goals += 1
        instance.plus_minus += 1
      end
    end

    case event.event_type
    when "EVG", "SHG"
      instance.plus_minus -= 1
    end

    instance.save

        # event_log = Event.includes("log_entries").where(log_entries: { event: event })

        #edit tallies, based on whether this special event matches an opposing team event or not
        # event.log_entries.
        # each do |entry|
        #   if opposing_team_events.
        #     any? do |event|
        #       event.log_entries.
        #       include? entry end #make this a select statement for conciseness
        #       instance = event.instance

        #
        # instance =
        # event.instances.
        #   find do |instance|
        #   instance.events.
        #     select do |evnt|
        #       evnt.player_id_nums


        # else

       # event.log_entries.each
     #if ...
  end #(method)

end


# *1-
# (improvement?)
#  process special events for a game instead of per team
#  add an event into an instance_events array within create_units_and_instances

  # integration means only tally +/- per game rather than for each team

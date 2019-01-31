# process special events per game, for one side

module ProcessSpecialEvents
  include Utilities

  def process_special_events (team, roster, game)
    @team, @roster, @game = team, roster, game

    get_special_events_data
    @team_events =
    @special_events - @opposing_team_events

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
    where( events: { game_id: @game.id } ).
    where.not( events: { event_type: 'shift'} )

    @opposing_team_events =
    @special_events.
    reject do |event|
      @roster.players.
      any? do |player|
        player.player_id_num == event.player_id_num end
    end
  end #get_special_events_data

  def associate_events_to_instances (events)
    events.
    map do |event|
      # find the special event's corresponding instance
      cspg_instance =
      @game_instances.
      find do |instance|
        true
        # instance_end_time = TimeOperation.new(:+, instance.start_time, instance.duration).result
        #
        # (event.end_time > instance.start_time && event.end_time <= instance_end_time && instance.events.first.period == event.period)
      end
      byebug
      cspg_instance.events << event if (cspg_instance.events & [event]).empty?

      Hash[instance: cspg_instance, event: event]
    end

  end #associate_events_to_instances

  def tally_special_events (data, team_event=false)
    event = data[:event]; instance = data[:instance];
    delta = -1; instance.plus_minus ||= 0 # use default values for instances

    if team_event
      event.log_entries.
      each do |log_entry|
        case log_entry.action_type
        when "assist", "primary", "secondary"
          instance.assists ||= 0; instance.assists += 1
        when "goal"
          instance.goals ||= 0; instance.goals += 1
          delta = 1
        end
      end
    end

    case event.event_type
    when "EVG", "SHG"
      instance.plus_minus += delta
    end

    instance.save
  end #(method)

  module_function :get_special_events_data,
  :associate_events_to_instances, :tally_special_events, :process_special_events
end


# *1-
# (improvement?)
#  process special events for a game instead of per team
#  add an event into an instance_events array within create_units_and_instances

  # integration means only tally +/- per game rather than for each team

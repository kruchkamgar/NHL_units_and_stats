require 'process_special_events'
# require_relative './data/events_hashes'
# require_relative './data/players_and_profiles'

describe 'ProcessSpecialEvents' do
  before(:context) {
    roster = Roster.where(team_id: 1).take
    ProcessSpecialEvents.instance_variable_set(
      :@roster, roster
    )
    game = Game.where(id: 1).take
    ProcessSpecialEvents.instance_variable_set(
      :@game, game
    )
  }

  describe '#get_special_events_data' do
    let(:run) { ProcessSpecialEvents.get_special_events_data }

    it 'retrieves game instance and event data' do
      run
      special_events_variable = ProcessSpecialEvents.instance_variable_get(:@special_events)

      expect(special_events_variable).
      to include(
        a_kind_of(Event)
      )
      expect(special_events_variable).
      not_to include(
        have_attributes(event_type: "shift")
      )
    end

    it 'selects opposing team events' do
      run

      expect(
        ProcessSpecialEvents.instance_variable_get(:@opposing_team_events).count
      ).
      to eq(1)
    end
  end

  describe '#associate_events_to_instances' do

    let(:run) {
      ProcessSpecialEvents.associate_events_to_instances(
      Event.where.not(event_type: 'shift')
    ) }
    it 'matches concurrent events to instances' do
      game_instances = Instance.all
      ProcessSpecialEvents.instance_variable_set(
        :@game_instances, game_instances
      )

      expect(run).
      to include(
        event: a_kind_of(Event),
        instance: a_kind_of(Instance)
      )
    end
  end

  let(:instance) { instance = Instance.new(); }
  let(:data) {
    event = Event.where.not(event_type: 'shift').take
    event.log_entries <<
      [ LogEntry.new(action_type: "goal"),
      LogEntry.new(action_type: "assist"),
      LogEntry.new(action_type: "assist") ]
    Hash[instance: instance, event: event] }
  describe '#tally_special_events' do
    it 'in- /decrements instance fields' do
      ProcessSpecialEvents.tally_special_events(data, true)
      expect(instance.plus_minus).to eq(1)
      expect(instance.assists).to eq(2)
      expect(instance.goals).to eq(1)
    end
  end

end

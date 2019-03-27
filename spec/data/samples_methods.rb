require './spec/data/samples_data'

module SamplesMethods
include SamplesData

  def units_sample
    unit = Unit.create
    instances_sample(unit.id)
  end

  def instances_sample(unit_id = nil, array_i = -1)
    instances_stats_data()[0..array_i]
    .map do |hash|
      hash.merge!(unit_id: unit_id ) if unit_id
      Instance.create( hash ) end
  end

end


# let(:units_groups_hash) {
#   abc_events = Event.all.sample(3)
#   abc_player_id_nums =
#   abc_events.map(&:player_id_num)
#   Hash[
#     [123, 234, 345] => [ Event.all.sample(3), Event.all.sample(3) ],
#     [543, 432, 321] => [ Event.all.sample(3), Event.all.sample(3) ],
#     abc_player_id_nums => [ abc_events ]
#   ]
# }
# let(:units) {
#   units_groups_hash.keys.
#   map.with_index do |unit, i|
#     Unit.new(id: i) end }
# let(:existing_units) {
#   instance =
#   Instance.create(id: 100)
#   instance.events << units_groups_hash
#     .values.last.flatten(1)
#   unit =
#   Unit.new(id:1)
#   unit.instances << instance; unit
# }

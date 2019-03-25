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

require './spec/data/samples_methods.rb'

describe Tally, type: :model do

include SamplesMethods
before do units_sample() end

  describe 'tally_instances_process' do
    let(:tally) do
      Unit.first.tallies.build end

    it 'maps instances, tallies, and sets the total' do
      expect( tally.map_reduce_and_total(:ppg) )
      .to eq(2)
    end
    it 'tallies the instance columns' do
      tally.tally_instances
      expect(tally.ppga)
      .to eq(2)
    end

  end
end

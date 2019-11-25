require 'live_data'
require './spec/data/seed_live_game_data.rb'

require 'sidekiq/testing'
Sidekiq::Testing.inline!

describe 'live_data' do

  before do @time_stamp = "20191117_052854" end
  let(:instance) do
    Hash[
      start_time: "00:01",
      game_id: "123567" ] end

  describe '#perform' do

    it "caches and fetches a diffPatch" do
      live_data = LiveData.new
      allow(live_data).to receive(:fetch_diff_patch).with(
        a_kind_of(Integer), a_kind_of(String) )
      .and_return(
        method("time_stamp_#{@time_stamp}").call )

      expect(live_data.perform( instance ))
      # .to
    end

  end

end

require 'live_data'
require './spec/data/seed_live_game_data.rb'

require 'sidekiq/testing'
Sidekiq::Testing.inline!

describe 'live_data' do

  before do
    @time_stamp = "20191117_052854"

    LiveData.time_stamp = @time_stamp
    Rails.cache.clear
  end
  let(:instance) do
    Hash[
      game_id: "123567",
      on_ice_plus: Array.new, # add prior state here
      plays: Array.new,
      on_ice_diff: Array.new ] end

  describe '#perform' do

    it "caches and fetches a diffPatch" do
      live_data = LiveData.new
      allow(live_data).to receive(:fetch_diff_patch).with(
        a_kind_of(String), a_kind_of(String) )
      .and_return(
        method("time_stamp_#{@time_stamp}").call )

      expect(live_data.perform( instance ))
      # .to
    end

  end

end

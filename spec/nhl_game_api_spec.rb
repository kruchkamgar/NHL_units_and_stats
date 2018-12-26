require 'NHL_game_api'

describe NHLGameAPI do

  describe 'NHLGameAPI::Adapter' do
    game_id = 2017020019
    let(:adapter) { NHLGameAPI::Adapter.new(game_id: game_id) }

    describe '#create_game' do

      it 'creates a game and fetches teams_hash' do
        allow(Game).to  receive(:find_or_create_by).and_return(Game.new(game_id: game_id))

        returned_array = adapter.create_game

        expect(returned_array.first.home_side).to eq("New Jersey Devils")
      end
    end

  end # describe NHLGameAPI::Adapter

end

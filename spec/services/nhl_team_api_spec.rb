require 'NHL_Team_API'

describe NHLTeamApi do

  describe 'NHLTeamApi::Adapter' do
    let(:team) { NHLTeamApi::Adapter.new(:team_id => 1, :season => "20172018") }
    let(:no_season) { NHLTeamApi::Adapter.new(:team_id => 1) }

      describe '#initialize' do

        context 'with custom options' do

          it 'initializes an adapter' do
            expect(team.instance_variable_get(:@team_id)).to eq(1)
          end
        end

        context 'without custom options' do

          it 'gets a correct season, for fall' do
            fixed = Date.new(2018, 10)
            allow(Date).to receive(:current).and_return(fixed)

            expect(no_season.instance_variable_get(:@season)).to eq("20182019")
          end

          it 'gets a correct season, for spring' do
            fixed = Date.new(2017, 1)
            allow(Date).to receive(:current).and_return(fixed)

            expect(no_season.instance_variable_get(:@season)).to eq("20162017")
          end
        end # without custom options

      end # #initialize

      describe '#fetch_data, with season options only.' do

        it 'fetches data for correct year.' do
          expect(team.fetch_data["dates"].first["date"]).to include("2017")
        end

      end

  end
end

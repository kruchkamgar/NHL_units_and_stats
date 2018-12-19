require 'rails_helper'
require 'NHL_Team_API'

describe NHLTeamAPI do

  describe 'NHLTeamAPI::Adapter' do
    let(:team) { NHLTeamAPI::Adapter.new(:team_id => 1, :season => "20172018") }

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

            expect(team.instance_variable_get(:@season)).to eq("20182019")
          end

          it 'gets a correct season, for spring' do
            fixed = Date.new(2018, 1)
            allow(Date).to receive(:current).and_return(fixed)

            expect(team.instance_variable_get(:@season)).to eq("20172018")
          end
        end # without custom options

      end # #initialize

      describe '#get_sched_url' do

        it 'returns the team url' do
          expect(team.get_sched_url).to eq('https://statsapi.web.nhl.com/api/v1/schedule?teamId=1&startDate=
        end
      end

      describe '#fetch_data' do

        it 'returns data' do

        end
      end


        # it 'creates a team' do
        #   #test create team
        # end
        #
        # it 'fetches a schedule url' do
        #   #....
        # end

  end
end

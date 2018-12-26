require 'create_roster'
require './data/team_hash'
require './data/game'

# create game
# create roster w/ and without the game; (roster could exist without this game)

# let(:roster_w_game) { Roster.new (team_id: 1) }
  # (do this after) roster_w_game.game = game

# describe 'roster_and_players_creation_logic' do
#   allow(Roster).to receive(:includes).and_return(true)
#   allow(roster_exists).to receive(:game).and_return(game)
#   allow(roster_exists).to receive(:players).and_return(@players)




# describe 'create new profiles'
  # create players
  # create player_profiles for game

describe CreateRoster do

  let!(:team) { Team.new(team_id:1, ) }

  team, game =

  describe 'add_profiles_to_game' do
    # allow(@players).to receive(:includes).and_return(...playerprofiles )
  end

end

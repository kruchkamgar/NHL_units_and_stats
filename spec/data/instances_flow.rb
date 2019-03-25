require_relative './seed_methods.rb'
require_relative './data.rb'

# class TestSeed

include SeedMethods
  def seed_team_and_players
    create_team # creates roster also
    @team_hash = get_team_hash() # data.rb
    players, @player_profiles =
    create_and_associate_profiles_and_players()
  end

  def seed_game
    create_game(@player_profiles)
  end

  def seed_events
    create_events()
  end

include CreateUnitsAndInstances
  def units_groups_hash_penalties
    create_records_from_shifts()
  end

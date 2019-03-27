require_relative './seed_methods.rb'
require_relative './data.rb'

# class TestSeed

include SeedMethods
  def seed_team_and_players
    create_team # creates roster also
    @team_hash = get_team_hash() unless @team_hash # set @team_hash, from data.rb
    players, @player_profiles =
    create_and_associate_profiles_and_players() end

  def seed_game
    create_game(@player_profiles) end

  def seed_events
    @events_hashes = events_hashes() unless @events_hashes # from data.rb
    create_game_events_and_log_entries_() # via NHLGameEventsAPI
  end

  def seed_all
    seed_team_and_players()
    seed_game(); seed_events()
  end

include CreateUnitsAndInstances
  def units_groups_hash_(pre_seed: false)
    seed_all() if pre_seed
    create_records_from_shifts()
  end

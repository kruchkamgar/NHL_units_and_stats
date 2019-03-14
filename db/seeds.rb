# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require './spec/data/data.rb'
# require './spec/data/events_flow'
require './spec/data/test_methods'
# require './lib/utilities.rb'

include SeedMethods
def run_seeds
  destroy_all_db
  create_and_associate_profiles_and_players
  create_game
  create_team
  create_roster
  @events_hashes = events_hashes() # data.rb
  create_events_sampling
  create_instances
end

def destroy_all_db
  LogEntry.destroy_all
  Circumstance.destroy_all

  Event.destroy_all
  PlayerProfile.destroy_all
  Instance.destroy_all

  Tally.destroy_all
  Unit.destroy_all

  Player.destroy_all
  Game.destroy_all
  Roster.destroy_all
  Team.destroy_all

  ApplicationRecord.connection.execute("DELETE FROM games_units")

  ApplicationRecord.connection.execute("DELETE FROM games_rosters")
  ApplicationRecord.connection.execute("DELETE FROM players_rosters")
  ApplicationRecord.connection.execute("DELETE FROM rosters_units")

  ApplicationRecord.connection.execute("DELETE FROM events_instances")
end


run_seeds

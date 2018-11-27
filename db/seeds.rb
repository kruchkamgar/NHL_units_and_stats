# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

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

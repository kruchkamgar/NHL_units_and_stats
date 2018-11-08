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
Unit.destroy_all

Player.destroy_all
Game.destroy_all
Roster.destroy_all
Team.destroy_all

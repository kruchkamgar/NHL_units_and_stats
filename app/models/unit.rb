class Unit < ApplicationRecord
  has_many :player_profiles, through: :circumstances # injury? 1st, 2nd, 3rd shift of the night?
  has_and_belongs_to_many :games

  # has_and_belongs_to_many :rosters # does this assocation matter if only theoretical, given games manifest unit exigence? ––
  has_many :rosters, through: :games
end

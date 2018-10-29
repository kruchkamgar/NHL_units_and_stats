class Unit < ApplicationRecord
  has_many :player_profiles, through: :circumstances # injury? 1st, 2nd, 3rd shift of the night?
  has_and_belongs_to_many :rosters
  has_many :games, through: :rosters
end

class Unit < ApplicationRecord
  has_many :player_profiles, through: :circumstances # injury? 1st, 2nd, 3rd shift of the night?
  has_many :instances, inverse_of: :unit
  # has_many :events, through: :instances
  has_many :player_profiles, through: :events
  has_and_belongs_to_many :games

  has_and_belongs_to_many :rosters # Units could conceivably manifest on multiple teams after trades --'reunited'
  has_one :tally
end

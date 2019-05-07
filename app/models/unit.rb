class Unit < ApplicationRecord
  has_many :circumstances
  has_many :player_profiles, through: :circumstances # injury? 1st, 2nd, 3rd shift of the night?
  has_many :instances
  # has_many :events, through: :instances
  has_many :player_profiles, through: :events
  has_and_belongs_to_many :games

  has_and_belongs_to_many :rosters # Units could conceivably manifest on multiple teams after trades --'reunited'
  has_many :tallies #one per season

  # simply saves on a couple 'reject' conditions
  has_many :stats, -> { select(:unit_id, :ppg, :ppga, :shg, :shga, :goals, :assists, :points, :plus_minus, :TOI) }, class_name: "Tally"
end

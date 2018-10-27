class Game < ApplicationRecord

  has_and_belongs_to_many :rosters # a roster instance may occur in many games
  has_many :teams, through: :rosters
  has_and_belongs_to_many :units # a subset of units, derived from a roster, may manifest in a particular game

  has_many :players, through: :rosters



end

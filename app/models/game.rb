class Game < ApplicationRecord

  has_and_belongs_to_many :rosters # a roster instance may occur in many games
  has_many :teams, through: :rosters
  has_and_belongs_to_many :units # *1

  # has_many :players, through: :rosters



end


# *1-  direct assocation - instead of through rosters - because only a subset of a roster's manifest units, may manifest in a particular game

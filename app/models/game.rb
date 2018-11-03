class Game < ApplicationRecord
  has_many :events
  has_and_belongs_to_many :rosters # a roster instance may reoccur for many games
  has_many :teams, through: :rosters
  has_and_belongs_to_many :units # *1
  has_and_belongs_to_many :player_profiles #until API allows shift-level player-position detail


  # has_many :players, through: :rosters



end


# *1-  direct assocation - instead of through rosters - because only a subset of a roster's manifest units, may manifest in a particular game

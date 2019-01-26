class Game < ApplicationRecord
  has_many :events
  has_and_belongs_to_many :rosters # many games may manifest a given roster
  has_many :teams, through: :rosters
  has_and_belongs_to_many :units # *1
  has_and_belongs_to_many :player_profiles # *2


  # has_many :players, through: :rosters



end


# *1-
# direct assocation - instead of through rosters - because only a subset of a roster's manifest units, may manifest in a particular game

# *2-
# associates which games involved a player profile (player position)
# until API allows shift-level player-position detail
# -at which point, can associate player_profiles to a game, via the events or instances

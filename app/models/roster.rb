# indicates the [prior] intention of a line-up, where players have PRIMARY positions [specified in one of their profiles].

class Roster < ApplicationRecord

  has_and_belongs_to_many :games # a game has two rosters, one for either team.
  has_and_belongs_to_many :players # *1
  has_many :units, through: :games
  belongs_to :team

end

# has_and_belongs_to_many :units #redundant w/ players (could use has_many :players -> {includes :units} )

# *1-
# has_many players through player_profiles
# - if/when creating roster based on player_profile (defined by player primary position)
 

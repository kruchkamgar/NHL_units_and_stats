class Roster < ApplicationRecord

  has_and_belongs_to_many :games # a game has two rosters, one for either team.
  has_and_belongs_to_many :players #has_many players through player_profiles?
  has_many :units, through: :games
  belongs_to :team

end


# has_and_belongs_to_many :units #redundant w/ players (could use has_many :players -> {includes :units} )

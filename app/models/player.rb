class Player < ApplicationRecord
  has_and_belongs_to_many :rosters
  has_many :player_profiles

  #add a self-join for primary-position changes?

end

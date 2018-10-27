class Team < ApplicationRecord
    has_many :rosters
    has_many :games, through: :rosters

    # validate season?

end

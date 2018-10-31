class Team < ApplicationRecord
    has_many :rosters
    has_many :games, through: :rosters

    attr_reader :team_id, :season
    # validate season?

end

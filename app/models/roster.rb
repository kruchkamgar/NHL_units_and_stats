class Roster < ApplicationRecord
  has_and_belongs_to_many :units #redundant w/ players (could use has_many :players -> {includes :units} )
  has_and_belongs_to_many :games
  has_and_belongs_to_many :players
  has_many :units, through: :players
  belongs_to :team

end

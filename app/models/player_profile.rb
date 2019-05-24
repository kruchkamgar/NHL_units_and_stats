class PlayerProfile < ApplicationRecord
  belongs_to :player # player_profiles hold relevant data; make this has_one
  has_many :log_entries
  has_many :events, through: :log_entries
  has_many :circumstances
  has_many :units, through: :circumstances # players may have different roles on different units...perhaps this may hold data surrounding player function on a unit --TBD.

  has_and_belongs_to_many :games
end

class PlayerProfile < ApplicationRecord
  belongs_to :player
  has_many :logs
  has_many :events, through: :logs
  has_many :circumstances
  has_many :units, through: :circumstances # players may have different roles on different units (a center may play wing, instead, on a [niche] unit)
end

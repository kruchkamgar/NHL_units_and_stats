class Instance < ApplicationRecord
  belongs_to :unit
  has_many :events
end

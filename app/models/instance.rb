class Instance < ApplicationRecord
  belongs_to :unit, optional: true
  has_many :events

end

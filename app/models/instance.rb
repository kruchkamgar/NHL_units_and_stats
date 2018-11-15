class Instance < ApplicationRecord
  belongs_to :unit, optional: true
  has_and_belongs_to_many :events

end

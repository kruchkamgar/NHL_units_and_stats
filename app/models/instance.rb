class Instance < ApplicationRecord
  belongs_to :unit, inverse_of: :instances, optional: true
  has_and_belongs_to_many :events

  # give goals and assists default value of 0
  # nil for +/- as initialization state. useful?

end

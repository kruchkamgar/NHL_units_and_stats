class Tally < ApplicationRecord
  belongs_to :unit
# implement starting value of 0 for assists and goals and points

  def tally_unit
      plus_minus_values =
      self.unit.instances.
      map(&:plus_minus).compact
      self.plus_minus =
      plus_minus_values.reduce(:+) if plus_minus_values.any?

      assist_values =
      self.unit.instances.
      map(&:assists).compact
      self.assists =
      assist_values.reduce(:+) if assist_values.any?

      goals_values =
      self.unit.instances.
      map(&:goals).compact
      self.goals =
      goals_values.reduce(:+) if goals_values

      self.points =
      self.goals + self.assists if self.goals && self.assists
  end

  def map_reduce_this (item, method, operation = :+)
    item.
    map(& method).
    reduce(operation)
  end

end

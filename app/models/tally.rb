class Tally < ApplicationRecord
  belongs_to :unit
# implement starting value of 0 for assists and goals and points

  def tally_instances
      plus_minus_values =
      self.unit.instances.
      map(&:plus_minus).compact
      self.plus_minus =
      plus_minus_values.reduce(:+) if plus_minus_values.any?

      assists_values =
      self.unit.instances.
      map(&:assists)
      self.assists =
      assists_values.reduce(:+) if assists_values.any?

      goals_values =
      self.unit.instances.
      map(&:goals)
      self.goals =
      goals_values.reduce(:+) if goals_values.any?

      # if self.goals > 0 && self.assists > 0 then $interrupt = true end

      self.points =
      self.goals + self.assists

  end

  # def map_reduce_this (item, method, operation = :+)
  #   item.
  #   map(& method).
  #   reduce(operation)
  # end

end

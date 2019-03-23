class Tally < ApplicationRecord
  belongs_to :unit
  # belongs_to :team
# implement starting value of 0 for assists and goals and points

  #  *1 - conceivably store these in table, with game_ids

  def tally_instances
    plus_minus_values

    Instance.columns
    .select do |col|
      col.type == :integer &&
      col.default == "0" end
    .each do |field|
      map_reduce_and_total(field) end
  end

  def tally_derivatives
    self.points =
    self.goals + self.assists
  end
  def map_reduce_and_total(method, operation = :+)
    total =
    self.unit.instances
    .map(& method)
    .reduce(operation)

    self.send(method) = total
  end

  def plus_minus_values
      plus_minus_values =
      self.unit.instances.
      map(&:plus_minus).compact
      self.plus_minus =
      plus_minus_values.reduce(:+) if plus_minus_values.any?
  end

  # def assists_values
  #     assists_values =
  #     self.unit.instances.
  #     map(&:assists)
  #     self.assists =
  #     assists_values.reduce(:+) if assists_values.any?
  # end
  # def goals_values
  #     goals_values =
  #     self.unit.instances.
  #     map(&:goals)
  #     self.goals =
  #     goals_values
  #     .reduce(:+) if goals_values.any?
  # end


end

class Tally < ApplicationRecord
  belongs_to :unit

  def tally_unit
      self.plus_minus =
      self.unit.instances.
      map(&:plus_minus).compact.
      reduce(:+) if instance.plus_minus

      self.assists =
      self.unit.instances.
      map(&:assists).compact.
      reduce(:+) if instance.assists

      self.goals =
      self.unit.instances.
      map(&:goals).compact.
      reduce(:+) if instance.goals

      self.points = self.goals + self.assists
  end

  def map_reduce_this (item, method, operation = :+)
    item.
    map(& method).
    reduce(operation)
  end

end

class ChangeDefaultValuesForTallies < ActiveRecord::Migration[5.2]
  def change
    change_column_default :tallies, :points, from: nil, to: 0
    change_column_default :tallies, :goals, from: nil, to: 0
    change_column_default :tallies, :assists, from: nil, to: 0
  end
end

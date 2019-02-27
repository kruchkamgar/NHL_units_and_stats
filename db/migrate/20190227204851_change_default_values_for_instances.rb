class ChangeDefaultValuesForInstances < ActiveRecord::Migration[5.2]
  def change
    change_column_default :instances, :points, from: nil, to: 0
    change_column_default :instances, :goals, from: nil, to: 0
    change_column_default :instances, :assists, from: nil, to: 0
  end
end

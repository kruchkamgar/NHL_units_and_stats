class ChangePlusMinusToAllowNull < ActiveRecord::Migration[5.2]
  def up
    change_column :tallies, :plus_minus, :integer, null: true
  end
  def down
    change_column :tallies, :plus_minus, :integer, null: false
  end
end

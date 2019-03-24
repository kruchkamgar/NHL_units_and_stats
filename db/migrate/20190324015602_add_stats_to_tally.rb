class AddStatsToTally < ActiveRecord::Migration[5.2]
  def change
    add_column :tallies, :ppga, :integer, default: 0
    add_column :tallies, :ppg, :integer, default: 0
    add_column :tallies, :shg, :integer, default: 0
    add_column :tallies, :shga, :integer, default: 0
  end
end

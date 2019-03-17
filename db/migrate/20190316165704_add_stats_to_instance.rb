class AddStatsToInstance < ActiveRecord::Migration[5.2]
  def change
    add_column :instances, :ppga, :integer, default: 0
    add_column :instances, :shga, :integer, default: 0
    add_column :instances, :ppg, :integer, default: 0
    add_column :instances, :shg, :integer, default: 0
  end
end

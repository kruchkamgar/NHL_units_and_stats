class AddStatsToInstance < ActiveRecord::Migration[5.2]
  def change
    add_column :instances, :ppga, :integer
    add_column :instances, :shga, :integer
    add_column :instances, :ppg, :integer
    add_column :instances, :shg, :integer
  end
end

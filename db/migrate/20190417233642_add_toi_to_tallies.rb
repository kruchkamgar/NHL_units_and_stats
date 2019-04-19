class AddToiToTallies < ActiveRecord::Migration[5.2]
  def change
    add_column :tallies, :TOI, :string, default: "0"
  end
end

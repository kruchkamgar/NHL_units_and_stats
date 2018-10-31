class RemoveColumnsFromPlayers < ActiveRecord::Migration[5.2]
  def change
    remove_column :players, :position, :string
    remove_column :players, :position_type, :string
  end
end

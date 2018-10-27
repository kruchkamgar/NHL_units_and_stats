class RemovePlayerIdFromEvents < ActiveRecord::Migration[5.2]
  def change
    remove_column :events, :player_id, :integer
  end
end

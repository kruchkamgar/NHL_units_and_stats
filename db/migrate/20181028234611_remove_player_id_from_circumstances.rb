class RemovePlayerIdFromCircumstances < ActiveRecord::Migration[5.2]
  def change
    remove_column :circumstances, :player_id, :integer
  end
end

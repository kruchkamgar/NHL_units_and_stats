class AddPlayerIdNumToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :player_id_num, :integer
  end
end

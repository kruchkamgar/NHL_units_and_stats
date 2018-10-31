class AddColumnsToPlayerProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :player_profiles, :position, :string
    add_column :player_profiles, :position_type, :string
  end
end

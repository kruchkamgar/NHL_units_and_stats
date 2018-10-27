class AddSeasonToTeam < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :season, :string
  end
end

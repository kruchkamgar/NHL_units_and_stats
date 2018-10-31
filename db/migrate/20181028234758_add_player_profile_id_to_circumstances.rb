class AddPlayerProfileIdToCircumstances < ActiveRecord::Migration[5.2]
  def change
    add_reference :circumstances, :player_profile, foreign_key: true
  end
end

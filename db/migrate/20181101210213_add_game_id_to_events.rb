class AddGameIdToEvents < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :game
  end
end

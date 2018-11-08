class AddInstanceIdToEvents < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :instance, foreign_key: true
  end
end

class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.references :player, index: {:unique=>true}, foreign_key: true

      t.timestamps
    end
  end
end

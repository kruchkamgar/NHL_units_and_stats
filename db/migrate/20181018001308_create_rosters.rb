class CreateRosters < ActiveRecord::Migration[5.2]
  def change
    create_table :rosters do |t|
      t.boolean :baseline
      t.string :type
      t.references :team, index: {:unique => true},
      foreign_key: true

      t.timestamps
    end
  end
end

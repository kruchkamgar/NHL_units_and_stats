class CreateTallies < ActiveRecord::Migration[5.2]
  def change
    create_table :tallies do |t|
      t.references :unit, foreign_key: true
      t.integer :assists
      t.integer :plus_minus
      t.integer :goals
      t.integer :points
      t.timestamps
    end
  end
end

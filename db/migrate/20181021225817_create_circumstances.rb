class CreateCircumstances < ActiveRecord::Migration[5.2]
  def change
    create_table :circumstances do |t|
      t.references :unit, foreign_key: true
      t.references :player, foreign_key: true

      t.timestamps
    end
  end
end

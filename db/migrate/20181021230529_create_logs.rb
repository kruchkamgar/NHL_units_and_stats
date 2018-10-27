class CreateLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :logs do |t|
      t.references :player, foreign_key: true
      t.references :event, foreign_key: true

      t.timestamps
    end
  end
end

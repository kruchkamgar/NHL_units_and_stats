class CreateLiveDataState < ActiveRecord::Migration[6.0]
  def change
    create_table :live_data_states do |t|
      t.string :start_time
      t.integer :game_id
    end
  end
end

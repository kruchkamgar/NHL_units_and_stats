class ChangeDateTimeToString < ActiveRecord::Migration[5.2]
  def change
    change_column :events, :duration, :string
    change_column :events, :end_time, :string
    change_column :events, :start_time, :string
  end
end

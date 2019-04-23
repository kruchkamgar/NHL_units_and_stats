class ChangeDateTimeToString < ActiveRecord::Migration[5.2]
  def up
    change_column :events, :duration, :string
    change_column :events, :end_time, :string
    change_column :events, :start_time, :string
  end
  def down
    remove_column :events, :duration
    remove_column :events, :end_time
    remove_column :events, :start_time

    add_column :events, :duration, :datetime
    add_column :events, :end_time, :datetime
    add_column :events, :start_time, :datetime
  end
end

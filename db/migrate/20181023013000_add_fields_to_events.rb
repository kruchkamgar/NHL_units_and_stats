class AddFieldsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :event_type, :string
    add_column :events, :duration, :datetime
    add_column :events, :start_time, :datetime
    add_column :events, :end_time, :datetime
    add_column :events, :shift_number, :integer
    add_column :events, :period, :integer
  end
end

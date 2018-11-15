class CreateJoinTableInstancesEvents < ActiveRecord::Migration[5.2]
  def change
    create_join_table :instances, :events do |t|
      t.index [:instance_id, :event_id]
      t.index [:event_id, :instance_id]
    end
  end
end

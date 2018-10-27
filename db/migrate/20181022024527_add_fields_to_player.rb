class AddFieldsToPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :position, :string
    add_column :players, :position_type, :string
  end
end

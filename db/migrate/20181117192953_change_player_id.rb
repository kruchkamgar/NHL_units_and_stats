class ChangePlayerId < ActiveRecord::Migration[5.2]

    # reversible do |dir|
    #     dir.up do
    #       # add a CHECK constraint
    #       execute <<-SQL
    #         ALTER TABLE player_profiles
    #           DROP FORIEGN KEY CONSTRAINT
    #       SQL
    #     end
    #     dir.down do
    #       execute <<-SQL
    #         ALTER TABLE player_profiles
    #           ADD FOREIGN KEY CONSTRAINT
    #       SQL
    #     end
    #   end

  def up
    drop_table :player_profiles
    rename_column :players, :player_id, :player_id_num

    create_table :player_profiles do |t|
      t.references :player, foreign_key: true
      t.string :position
      t.string :position_type
      t.timestamps
    end

  end

  def down
    drop_table :player_profiles
    rename_column :players, :player_id_num, :player_id

    create_table :player_profiles do |t|
      t.references :player, foreign_key: true
      t.string :position
      t.string :position_type
      t.timestamps
    end
  end

end

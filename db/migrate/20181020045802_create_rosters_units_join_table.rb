class CreateRostersUnitsJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :rosters, :units do |t|
      t.index [:roster_id, :unit_id]
      t.index [:unit_id, :roster_id]
    end
  end
end
# a particular roster implies the use of certain units (via the 'scratching' of players, due to injury or discretion– John is a 'healthy scratch' tonight)

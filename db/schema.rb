# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_11_14_190217) do

  create_table "circumstances", force: :cascade do |t|
    t.integer "unit_id"``
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_profile_id"
    t.index ["player_profile_id"], name: "index_circumstances_on_player_profile_id"
    t.index ["unit_id"], name: "index_circumstances_on_unit_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "event_type"
    t.string "duration"
    t.string "start_time"
    t.string "end_time"
    t.integer "shift_number"
    t.integer "period"
    t.integer "game_id"
    t.integer "player_id_num"
    t.index ["game_id"], name: "index_events_on_game_id"
  end

  create_table "events_instances", id: false, force: :cascade do |t|
    t.integer "instance_id", null: false
    t.integer "event_id", null: false
    t.index ["event_id", "instance_id"], name: "index_events_instances_on_event_id_and_instance_id"
    t.index ["instance_id", "event_id"], name: "index_events_instances_on_instance_id_and_event_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "game_id"
    t.string "home_side"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games_player_profiles", id: false, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_profile_id", null: false
  end

  create_table "games_rosters", id: false, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "roster_id", null: false
    t.index ["game_id", "roster_id"], name: "index_games_rosters_on_game_id_and_roster_id"
    t.index ["roster_id", "game_id"], name: "index_games_rosters_on_roster_id_and_game_id"
  end

  create_table "games_units", id: false, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "unit_id", null: false
    t.index ["game_id", "unit_id"], name: "index_games_units_on_game_id_and_unit_id"
    t.index ["unit_id", "game_id"], name: "index_games_units_on_unit_id_and_game_id"
  end

  create_table "instances", force: :cascade do |t|
    t.integer "unit_id"
    t.integer "assists"
    t.integer "plus_minus"
    t.integer "goals"
    t.integer "points"
    t.string "start_time"
    t.string "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_instances_on_unit_id"
  end

  create_table "log_entries", force: :cascade do |t|
    t.integer "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action_type"
    t.integer "player_profile_id"
    t.index ["event_id"], name: "index_log_entries_on_event_id"
    t.index ["player_profile_id"], name: "index_log_entries_on_player_profile_id"
  end

  create_table "player_profiles", force: :cascade do |t|
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "position"
    t.string "position_type"
    t.index ["player_id"], name: "index_player_profiles_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_id"
  end

  create_table "players_rosters", id: false, force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "roster_id", null: false
    t.index ["player_id", "roster_id"], name: "index_players_rosters_on_player_id_and_roster_id"
    t.index ["roster_id", "player_id"], name: "index_players_rosters_on_roster_id_and_player_id"
  end

  create_table "rosters", force: :cascade do |t|
    t.boolean "baseline"
    t.string "type"
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_rosters_on_team_id"
  end

  create_table "rosters_units", id: false, force: :cascade do |t|
    t.integer "roster_id", null: false
    t.integer "unit_id", null: false
    t.index ["roster_id", "unit_id"], name: "index_rosters_units_on_roster_id_and_unit_id"
    t.index ["unit_id", "roster_id"], name: "index_rosters_units_on_unit_id_and_roster_id"
  end

  create_table "tallies", force: :cascade do |t|
    t.integer "unit_id"
    t.integer "assists"
    t.integer "plus_minus"
    t.integer "goals"
    t.integer "points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_tallies_on_unit_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "season"
    t.integer "team_id"
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

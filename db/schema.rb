# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_24_200005) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "circumstances", force: :cascade do |t|
    t.bigint "unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "player_profile_id"
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
    t.bigint "game_id"
    t.integer "player_id_num"
    t.index ["game_id"], name: "index_events_on_game_id"
  end

  create_table "events_instances", id: false, force: :cascade do |t|
    t.bigint "instance_id", null: false
    t.bigint "event_id", null: false
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
    t.bigint "game_id", null: false
    t.bigint "player_profile_id", null: false
  end

  create_table "games_rosters", id: false, force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "roster_id", null: false
    t.index ["game_id", "roster_id"], name: "index_games_rosters_on_game_id_and_roster_id"
    t.index ["roster_id", "game_id"], name: "index_games_rosters_on_roster_id_and_game_id"
  end

  create_table "games_units", id: false, force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "unit_id", null: false
    t.index ["game_id", "unit_id"], name: "index_games_units_on_game_id_and_unit_id"
    t.index ["unit_id", "game_id"], name: "index_games_units_on_unit_id_and_game_id"
  end

  create_table "instances", force: :cascade do |t|
    t.bigint "unit_id"
    t.integer "assists", default: 0
    t.integer "plus_minus"
    t.integer "goals", default: 0
    t.integer "points", default: 0
    t.string "start_time"
    t.string "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ppga", default: 0
    t.integer "shga", default: 0
    t.integer "ppg", default: 0
    t.integer "shg", default: 0
    t.index ["unit_id"], name: "index_instances_on_unit_id"
  end

  create_table "live_data_states", force: :cascade do |t|
    t.string "start_time"
    t.integer "game_id"
  end

  create_table "log_entries", force: :cascade do |t|
    t.bigint "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action_type"
    t.bigint "player_profile_id"
    t.index ["event_id"], name: "index_log_entries_on_event_id"
    t.index ["player_profile_id"], name: "index_log_entries_on_player_profile_id"
  end

  create_table "player_profiles", force: :cascade do |t|
    t.bigint "player_id"
    t.string "position"
    t.string "position_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_profiles_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_id_num"
    t.index ["player_id_num"], name: "index_players_on_player_id_num", unique: true
  end

  create_table "players_rosters", id: false, force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "roster_id", null: false
    t.index ["player_id", "roster_id"], name: "index_players_rosters_on_player_id_and_roster_id"
    t.index ["roster_id", "player_id"], name: "index_players_rosters_on_roster_id_and_player_id"
  end

  create_table "rosters", force: :cascade do |t|
    t.boolean "baseline"
    t.string "type"
    t.bigint "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_rosters_on_team_id"
  end

  create_table "rosters_units", id: false, force: :cascade do |t|
    t.bigint "roster_id", null: false
    t.bigint "unit_id", null: false
    t.index ["roster_id", "unit_id"], name: "index_rosters_units_on_roster_id_and_unit_id"
    t.index ["unit_id", "roster_id"], name: "index_rosters_units_on_unit_id_and_roster_id"
  end

  create_table "tallies", force: :cascade do |t|
    t.bigint "unit_id"
    t.integer "assists", default: 0
    t.integer "plus_minus"
    t.integer "goals", default: 0
    t.integer "points", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ppga", default: 0
    t.integer "ppg", default: 0
    t.integer "shg", default: 0
    t.integer "shga", default: 0
    t.string "TOI", default: "0"
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

  add_foreign_key "circumstances", "units"
  add_foreign_key "instances", "units"
  add_foreign_key "log_entries", "events"
  add_foreign_key "player_profiles", "players"
  add_foreign_key "rosters", "teams"
  add_foreign_key "tallies", "units"
end

# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130806211023) do

  create_table "nfl_schedules", :force => true do |t|
    t.integer  "year"
    t.integer  "week"
    t.integer  "home_nfl_team_id"
    t.integer  "away_nfl_team_id"
    t.datetime "start_time"
    t.integer  "home_score"
    t.integer  "away_score"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "nfl_schedules", ["away_nfl_team_id"], :name => "index_nfl_schedules_on_away_nfl_team_id"
  add_index "nfl_schedules", ["home_nfl_team_id"], :name => "index_nfl_schedules_on_home_nfl_team_id"
  add_index "nfl_schedules", ["year", "week", "home_nfl_team_id", "away_nfl_team_id"], :name => "nfl_schedule_year_week_teams_uq", :unique => true

  create_table "nfl_teams", :force => true do |t|
    t.string   "city"
    t.string   "name"
    t.string   "abbreviation"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "division"
    t.string   "conference"
  end

  create_table "survivor_bets", :force => true do |t|
    t.integer  "survivor_entry_id"
    t.integer  "week"
    t.integer  "nfl_game_id"
    t.integer  "nfl_team_id"
    t.boolean  "is_correct"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "bet_number"
  end

  add_index "survivor_bets", ["nfl_game_id"], :name => "index_survivor_bets_on_nfl_game_id"
  add_index "survivor_bets", ["nfl_team_id"], :name => "index_survivor_bets_on_nfl_team_id"
  add_index "survivor_bets", ["survivor_entry_id", "nfl_team_id"], :name => "survivor_bets_entry_team_uq", :unique => true
  add_index "survivor_bets", ["survivor_entry_id", "week", "bet_number"], :name => "survivor_bets_entry_week_num_uq", :unique => true
  add_index "survivor_bets", ["survivor_entry_id"], :name => "index_survivor_bets_on_survivor_entry_id"

  create_table "survivor_entries", :force => true do |t|
    t.integer  "user_id"
    t.integer  "year"
    t.string   "game_type"
    t.boolean  "is_alive"
    t.boolean  "used_autopick"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "entry_number"
    t.integer  "knockout_week"
  end

  add_index "survivor_entries", ["user_id", "year", "game_type", "entry_number"], :name => "survivor_entries_user_year_type_num_uq", :unique => true
  add_index "survivor_entries", ["user_id"], :name => "index_survivor_entries_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "role"
    t.string   "captain_code"
    t.string   "referred_by"
    t.string   "auth_token"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.boolean  "send_emails",            :default => false, :null => false
    t.string   "time_zone"
  end

  add_index "users", ["email"], :name => "users_email_uq", :unique => true
  add_index "users", ["first_name", "last_name"], :name => "users_first_last_name_uq", :unique => true

  create_table "weeks", :force => true do |t|
    t.integer  "year"
    t.integer  "number"
    t.datetime "start_time"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "weeks", ["year", "number"], :name => "weeks_year_number_uq", :unique => true
  add_index "weeks", ["year", "start_time"], :name => "weeks_start_time_number_uq", :unique => true

end

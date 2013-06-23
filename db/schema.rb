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

ActiveRecord::Schema.define(:version => 20130622234541) do

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

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "users", ["email"], :name => "users_email_uq", :unique => true

end

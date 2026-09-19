# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_09_19_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.integer "rows", null: false
    t.integer "cols", null: false
    t.integer "flight_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id", "rows", "cols"], name: "index_bookings_on_flight_id_and_rows_and_cols", unique: true
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "flight_search_guards", force: :cascade do |t|
    t.jsonb "requests", default: [], null: false
    t.jsonb "clients", default: {}, null: false
    t.jsonb "searches", default: {}, null: false
  end

  create_table "flights", force: :cascade do |t|
    t.integer "plane_id"
    t.date "date"
    t.text "from"
    t.text "to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_key"
    t.string "flight_number"
    t.string "carrier"
    t.index ["schedule_key"], name: "index_flights_on_schedule_key", unique: true
  end

  create_table "planes", force: :cascade do |t|
    t.integer "rows"
    t.integer "cols"
    t.text "model"
    t.integer "plane_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.text "first_name"
    t.text "last_name"
    t.text "email"
    t.boolean "admin"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "bookings", "flights"
  add_foreign_key "bookings", "users"
end

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

ActiveRecord::Schema[7.1].define(version: 2024_06_20_155922) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "gtfs_routes", force: :cascade do |t|
    t.string "code"
    t.string "short_name"
    t.string "long_name"
    t.string "bg_color"
    t.string "text_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gtfs_stop_times", force: :cascade do |t|
    t.bigint "gtfs_trip_id", null: false
    t.datetime "departure_time"
    t.datetime "arrival_time"
    t.integer "stop_sequence"
    t.bigint "gtfs_stop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtfs_stop_id"], name: "index_gtfs_stop_times_on_gtfs_stop_id"
    t.index ["gtfs_trip_id"], name: "index_gtfs_stop_times_on_gtfs_trip_id"
  end

  create_table "gtfs_stops", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.geometry "geom", limit: {:srid=>0, :type=>"st_point"}
    t.bigint "parent_stop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_stop_id"], name: "index_gtfs_stops_on_parent_stop_id"
  end

  create_table "gtfs_trips", force: :cascade do |t|
    t.bigint "gtfs_route_id", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtfs_route_id"], name: "index_gtfs_trips_on_gtfs_route_id"
  end

  create_table "isochrones", force: :cascade do |t|
    t.geometry "geom", limit: {:srid=>0, :type=>"geometry"}
    t.geometry "center", limit: {:srid=>0, :type=>"st_point"}
    t.integer "range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["center"], name: "index_isochrones_on_center", using: :gist
  end

  create_table "train_lines", force: :cascade do |t|
    t.string "code"
    t.geometry "geom", limit: {:srid=>0, :type=>"geometry"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "train_stations", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.geometry "lonlat", limit: {:srid=>0, :type=>"st_point"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lonlat"], name: "index_train_stations_on_lonlat", using: :gist
  end

  add_foreign_key "gtfs_stop_times", "gtfs_stops"
  add_foreign_key "gtfs_stop_times", "gtfs_trips"
  add_foreign_key "gtfs_stops", "gtfs_stops", column: "parent_stop_id"
  add_foreign_key "gtfs_trips", "gtfs_routes"
end

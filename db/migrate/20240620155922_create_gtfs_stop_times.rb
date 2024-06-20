class CreateGtfsStopTimes < ActiveRecord::Migration[7.1]
  def change
    create_table :gtfs_stop_times do |t|
      t.belongs_to :gtfs_trip, null: false, foreign_key: true
      t.datetime :departure_time
      t.datetime :arrival_time
      t.integer :stop_sequence
      t.belongs_to :gtfs_stop, null: false, foreign_key: true

      t.timestamps
    end
  end
end

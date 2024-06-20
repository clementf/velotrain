class CreateGtfsStops < ActiveRecord::Migration[7.1]
  def change
    create_table :gtfs_stops do |t|
      t.string :name
      t.string :code
      t.st_point :geom
      t.references :parent_stop, foreign_key: {to_table: :gtfs_stops}

      t.timestamps
    end
  end
end

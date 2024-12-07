class UpdateAllSridsTo4326 < ActiveRecord::Migration[7.1]
  def up
    # Update gtfs_stops table (currently srid: 0)
    change_column :gtfs_stops, :geom, :geometry, limit: { srid: 4326, type: "st_point" }
    
    # Update isochrones table (currently srid: 0)
    change_column :isochrones, :geom, :geometry, limit: { srid: 4326, type: "geometry" }
    change_column :isochrones, :center, :geometry, limit: { srid: 4326, type: "st_point" }
    
    # Update train_lines table (currently srid: 0)
    change_column :train_lines, :geom, :geometry, limit: { srid: 4326, type: "geometry" }
    
    # Update train_stations table (currently srid: 0)
    change_column :train_stations, :lonlat, :geometry, limit: { srid: 4326, type: "st_point" }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

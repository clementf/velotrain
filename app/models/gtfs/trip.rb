require "csv"

class Gtfs::Trip < ApplicationRecord
  belongs_to :route, class_name: "Gtfs::Route", foreign_key: "gtfs_route_id"

  def self.import(filepath)
    Gtfs::Trip.delete_all
    Gtfs::Trip.transaction do
      # route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id
      CSV.foreach(filepath, headers: true) do |row|
        Gtfs::Trip.create!(
          code: row["trip_id"],
          gtfs_route_id: Gtfs::Route.find_by(code: row["route_id"]).id
        )
      end
    end
  end
end

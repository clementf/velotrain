require "csv"

class Gtfs::Trip < ApplicationRecord
  belongs_to :route, class_name: "Gtfs::Route", foreign_key: "gtfs_route_id"

  def self.import_from_csv(filepath)
    Gtfs::Trip.delete_all

    route_id_cache = Gtfs::Route.pluck(:code, :id).to_h

    trips = []

    CSV.foreach(filepath, headers: true) do |row|
      gtfs_route_id = route_id_cache[row["route_id"]]

      trips << Gtfs::Trip.new(
        code: row["trip_id"],
        service_id: row["service_id"],
        gtfs_route_id: gtfs_route_id
      )
    end

    Gtfs::Trip.import(trips)
  end
end

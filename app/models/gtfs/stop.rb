require "csv"

class Gtfs::Stop < ApplicationRecord
  belongs_to :parent_stop, class_name: "Gtfs::Stop", foreign_key: "parent_stop_id", optional: true
  has_many :stop_times, class_name: "Gtfs::StopTime", foreign_key: "gtfs_stop_id"

  scope :train_stations, -> { where("code LIKE '%OCETrain%' OR code LIKE '%OCETramTrain%'") }
  scope :bus_stops, -> { where("code LIKE '%OCECar%'") }

  def self.import(filepath)
    Gtfs::Stop.delete_all
    Gtfs::Stop.transaction do
      # stop_id,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station
      CSV.foreach(filepath, headers: true) do |row|
        Gtfs::Stop.create!(
          code: row["stop_id"],
          name: row["stop_name"],
          geom: "POINT(#{row["stop_lon"]} #{row["stop_lat"]})",
          parent_stop_id: Gtfs::Stop.find_by(code: row["parent_station"])&.id
        )
      end
    end
  end
end

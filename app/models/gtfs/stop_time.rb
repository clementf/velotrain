require "csv"

class Gtfs::StopTime < ApplicationRecord
  belongs_to :trip, class_name: "Gtfs::Trip", foreign_key: :gtfs_trip_id
  belongs_to :stop, class_name: "Gtfs::Stop", foreign_key: :gtfs_stop_id
  has_one :route, through: :trip

  def self.import_from_csv(file)
    Gtfs::StopTime.delete_all

    trip_id_cache = Gtfs::Trip.pluck(:code, :id).to_h
    stop_id_cache = Gtfs::Stop.pluck(:code, :id).to_h

    batch_size = 4000
    batch = []

    CSV.foreach(file, headers: true) do |row|
      gtfs_trip_id = trip_id_cache[row["trip_id"]]
      gtfs_stop_id = stop_id_cache[row["stop_id"]]

      next unless gtfs_trip_id && gtfs_stop_id

      begin
        stop_time_attributes = {
          gtfs_trip_id: gtfs_trip_id,
          arrival_time: DateTime.parse(row["arrival_time"]),
          departure_time: DateTime.parse(row["departure_time"]),
          stop_sequence: row["stop_sequence"],
          gtfs_stop_id: gtfs_stop_id
        }
      rescue Date::Error => e
        puts "Error: #{e.message}"
        next
      end

      batch << Gtfs::StopTime.new(stop_time_attributes)

      if batch.size >= batch_size
        Gtfs::StopTime.import batch
        batch = []
      end
    end

    # Import any remaining records in the batch
    Gtfs::StopTime.import batch unless batch.empty?
  end
end

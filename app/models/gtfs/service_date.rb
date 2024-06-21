class Gtfs::ServiceDate < ApplicationRecord
  def self.import_from_csv(filepath)
    Gtfs::ServiceDate.delete_all

    service_dates = []

    CSV.foreach(filepath, headers: true) do |row|
      if row["exception_type"] == "2"
        next
      end

      service_dates << Gtfs::ServiceDate.new(
        date: row["date"],
        service_id: row["service_id"]
      )
    end

    Gtfs::ServiceDate.import(service_dates)
  end
end

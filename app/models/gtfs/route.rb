require "csv"

class Gtfs::Route < ApplicationRecord
  def self.import(filepath)
    Gtfs::Route.delete_all
    Gtfs::Route.transaction do
      # headers
      # route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color
      CSV.foreach(filepath, headers: true) do |row|
        Gtfs::Route.create(
          code: row["route_id"],
          short_name: row["route_short_name"],
          long_name: row["route_long_name"],
          bg_color: row["route_color"],
          text_color: row["route_text_color"]
        )
      end
    end
  end
end

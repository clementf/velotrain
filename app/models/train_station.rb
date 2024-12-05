require "csv"
class TrainStation < ApplicationRecord
  attribute :lonlat, :st_point, geographic: true, srid: 4326

  def gtfs_stop
    Gtfs::Stop.find_by(code: "StopArea:OCE#{uic_code}")
  end

  def lon
    lonlat.x
  end

  def lat
    lonlat.y
  end

  def to_combobox_display
    name.to_s
  end

  def area_id
    uic_code
  end

  def self.import(filepath)
    CSV.foreach(filepath, headers: true, col_sep: ";", encoding: "bom|utf-8") do |row|
      longitude, latitude = row["Position géographique"].split(",").map(&:to_f).reverse

      TrainStation.find_or_initialize_by(code: row["Trigramme"]).update(
        name: row["Nom"],
        drg: row["Segment(s) DRG"].first, # only take the first letter, which is the main segment (some are reported as "A:A" for example)
        lonlat: "POINT(#{longitude} #{latitude})",
        uic_code: row["Code(s) UIC"].split(";").first
      )
    end
  end
end

require "csv"
class TrainStation < ApplicationRecord

  UIC_CODES_WITHIN_PARIS = [
    "87547026", "87547000", # Austerlitz
    "87686667", # Bercy
    "87686030", "87686006", # Gare de Lyon
    "87391011", "87391003", "87391102", # Gare de Montparnasse
    "87271031", "87271007", "87271023", # Gare du Nord
    "87113001", # Gare de l'Est
    "87384008", # Saint-Lazare
  ]
  attribute :lonlat, :st_point, geographic: true, srid: 4326

  def gtfs_stop
    Gtfs::Stop.find_by(code: "StopArea:OCE#{uic_code}")
  end

  def isochrones
    Isochrone.where("ST_DWithin(center, ?, 0.0005)", lonlat) # About 50 meters at the equator
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

  def self.is_area_within_paris?(area_id)
    UIC_CODES_WITHIN_PARIS.include?(area_id)
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

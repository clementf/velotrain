require "csv"

class IsochroneImport
  def initialize(file_path)
    @file_path = file_path
  end

  def import
    CSV.foreach(@file_path, headers: true) do |row|
      isochrone = Isochrone.new
      isochrone.geom = RGeo::WKRep::WKTParser.new.parse(row["geom"])
      isochrone.center = RGeo::WKRep::WKTParser.new.parse(row["center"])
      isochrone.range = row["range_seconds"]
      isochrone.save!
    end
  end
end

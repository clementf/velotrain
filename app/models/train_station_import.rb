require "csv"

class TrainStationImport
  def initialize(file_path)
    @file_path = file_path
  end

  # imports a csv that has the following columns, skip byte order mark (BOM)
  # Nom;Trigramme;Segment(s) DRG;Position géographique;Code commune;Code(s) UIC
  def import
    CSV.foreach(@file_path, headers: true, col_sep: ";", encoding: "bom|utf-8") do |row|
      longitude, latitude = row["Position géographique"].split(",").map(&:to_f).reverse

      TrainStation.find_or_initialize_by(code: row["Trigramme"]).update(
        name: row["Nom"],
        lonlat: "POINT(#{longitude} #{latitude})"
      )
    end
  end
end

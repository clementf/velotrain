require "csv"

class TrainLineImport
  def initialize(filepath)
    @filepath = filepath
  end

  def import
    CSV.foreach(@filepath, col_sep: ";", headers: true) do |row|
      TrainLine.create!(
        code: row["CODE_LIGNE"],
        geom: RGeo::GeoJSON.decode(row["Geo Shape"])
      )
    end
  end
end

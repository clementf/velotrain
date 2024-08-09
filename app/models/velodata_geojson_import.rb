class VelodataGeojsonImport
  def initialize(file)
    @file = file
  end

  def import
    @data = JSON.parse(File.read(@file))

    @data["features"].each do |feature|
      track = Gpx::Track.create!(
        name: feature["properties"]["nom_iti"].strip
      )

      wkt_string = "LINESTRING (#{feature["geometry"]["coordinates"].flatten(1).map { |coord| coord.join(" ") }.join(", ")})"
      track.segments.create!(geom: wkt_string)
    end
  end
end

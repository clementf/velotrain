class VelodataGeojsonImport
  def initialize(file)
    @file = file
  end

  def import
    @data = RGeo::GeoJSON.decode(File.read(@file))

    @data.each do |feature|
      track = Gpx::Track.create!(
        name: feature.properties["nom_iti"]
      )

      track.segments.create!(
        geom: feature.geometry
      )
    end
  end
end

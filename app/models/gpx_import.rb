class GpxImport
  def initialize(file, track_name:)
    @file = file
    @track_name = track_name
  end

  def import_track_from_file
    ActiveRecord::Base.transaction do
      track = Gpx::Track.create!(name: @track_name)

      doc.css("trk").each do |trk|
        track.segments.create!(
          status: trk.css("desc").text,
          geom: "LINESTRING(#{trk.css("trkseg trkpt").map { |trkpt| "#{trkpt["lon"]} #{trkpt["lat"]} #{trkpt.css("ele").text}" }.join(", ")})"
        )
      end
    end

    true
  end

  private

  def doc
    Nokogiri::HTML(@file)
  end
end

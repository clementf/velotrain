class GpxImport
  def initialize(file, track)
    @file = file
    @track = track
  end

  def import_track_from_file
    ActiveRecord::Base.transaction do
      @track.segments.destroy_all

      doc.css("trk").each do |trk|
        @track.segments.create!(
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

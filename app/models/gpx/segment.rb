class Gpx::Segment < ApplicationRecord
  belongs_to :track, class_name: "Gpx::Track", foreign_key: :gpx_track_id, touch: true

  def distance_km
    query = <<-SQL
      SELECT ST_Length(geom) / 1000 AS distance
      FROM gpx_segments
      WHERE id = #{id};
    SQL

    result = ActiveRecord::Base.connection.execute(query).first
    result["distance"].to_f.round(2)
  end
end

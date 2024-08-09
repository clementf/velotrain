class Gpx::Segment < ApplicationRecord
  belongs_to :track, class_name: "Gpx::Track", foreign_key: :gpx_track_id, touch: true

  before_save :set_distance

  def set_distance
    self.distance = calculate_distance
  end

  def distance_km
    distance / 1000
  end

  private

  def calculate_distance
    query = <<-SQL
      SELECT ST_Length(geom) AS distance
      FROM gpx_segments
      WHERE id = #{id};
    SQL

    result = ActiveRecord::Base.connection.execute(query).first
    result["distance"].to_f.round(2)
  end
end

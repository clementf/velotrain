module Api
  class PathsController < ApplicationController
    FRANCE = "POLYGON ((1.82373 51.193115, -5.866699 48.57479, -1.845703 45.660127, -2.263184 42.988576, 3.427734 41.787697, 9.810791 41.29019, 9.492188 44.103365, 7.998047 43.779027, 7.349854 45.390735, 7.119141 46.679594, 8.052979 47.894248, 8.701172 49.037868, 5.559082 50.035974, 2.252197 51.323747, 1.82373 51.193115))"

    def index
      render json: {
        type: "FeatureCollection",
        features: gpx_segments.map do |segment|
          {
            type: "Feature",
            properties: {
              name: segment.track.name,
              status: segment.status
            },
            geometry: RGeo::GeoJSON.encode(segment.geom)
          }
        end
      }
    end

    private

    def gpx_segments
      Rails.cache.fetch("gpx_segments_#{cache_key}") do
        Rails.logger.info("Cache miss for gpx_segments_#{cache_key}")

        Gpx::Segment
          .includes(:track)
          .select("id, gpx_track_id, status, ST_Simplify(ST_Intersection(geom::geometry, ST_GeomFromText('#{FRANCE}', 4326)), #{simplification_factor}) AS geom")
      end
    end

    def cache_key
      "paths_for_zoom_#{params[:zoom]}}"
    end

    def simplification_factor
      zoom_level = params[:zoom].to_i

      case zoom_level
      when 0..7
        0.1
      when 7..10
        0.01
      when 10..12
        0.001
      else
        0.0001
      end
    end
  end
end

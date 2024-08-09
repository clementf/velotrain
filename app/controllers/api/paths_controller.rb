module Api
  class PathsController < ApplicationController
    FRANCE = "POLYGON ((1.82373 51.193115, -5.866699 48.57479, -1.845703 45.660127, -2.263184 42.988576, 3.427734 41.787697, 9.810791 41.29019, 9.492188 44.103365, 7.998047 43.779027, 7.349854 45.390735, 7.119141 46.679594, 8.052979 47.894248, 8.701172 49.037868, 5.559082 50.035974, 2.252197 51.323747, 1.82373 51.193115))"

    def index
      render json: {
        type: "FeatureCollection",
        features: gpx_segments.map do |segment|
          {
            type: "Feature",
            # properties: {
            #   name: segment.track.name,
            #   status: segment.status
            # },
            geometry: JSON.parse(segment.geom_json)
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
          .joins(:track)
          .select("gpx_segments.id, gpx_track_id, status, ST_AsGeoJSON(ST_Simplify(#{intersection_clause}, #{simplification_factor})) AS geom_json")
          .where("gpx_tracks.visible = true")
          .where(intersection_where_clause)
      end
    end

    def cache_key
      "#{simplified_bounds_to_maximize_cache_hits.join("_")}_#{params[:zoom]}}"
    end

    def intersection_where_clause
      if simplified_bounds_to_maximize_cache_hits.present?
        "ST_Intersects(geom::geometry, ST_MakeEnvelope(#{simplified_bounds_to_maximize_cache_hits.join(", ")}, 4326))"
      else
        "ST_Intersects(geom::geometry, ST_GeomFromText('#{FRANCE}', 4326))"
      end
    end

    def intersection_clause
      if simplified_bounds_to_maximize_cache_hits.present?
        "ST_Intersection(geom::geometry, ST_MakeEnvelope(#{simplified_bounds_to_maximize_cache_hits.join(", ")}, 4326))"
      else
        "ST_Intersection(geom::geometry, ST_GeomFromText('#{FRANCE}', 4326))"
      end
    end

    def simplified_bounds_to_maximize_cache_hits
      bounds = params[:bounds].split(",").map(&:to_f)

      # Define the amount of padding in degrees (adjust based on your needs)
      padding = 0.1 # For example, 0.001 degrees (about 111 meters at the equator)

      # If bounds are provided, add padding before rounding
      if bounds.any?
        # bounds are assumed to be in the format [min_lat, min_lon, max_lat, max_lon]
        min_lat, min_lon, max_lat, max_lon = bounds

        # Add padding
        min_lat -= padding
        min_lon -= padding
        max_lat += padding
        max_lon += padding

        # Round the bounds with padding to maximize cache hit rate
        [
          min_lat.round(4),
          min_lon.round(4),
          max_lat.round(4),
          max_lon.round(4)
        ]

        # Return or use the rounded bounds as needed

      else
        []
      end
    end

    def simplification_factor
      zoom_level = params[:zoom].to_i

      case zoom_level
      when 0..7
        5
      when 7..9
        0.01
      when 9..10
        0.001
      else
        0.0001
      end
    end
  end
end

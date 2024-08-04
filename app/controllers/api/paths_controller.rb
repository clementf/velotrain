module Api
  class PathsController < ApplicationController
    FRANCE = "POLYGON ((1.82373 51.193115, -5.866699 48.57479, -1.845703 45.660127, -2.263184 42.988576, 3.427734 41.787697, 9.810791 41.29019, 9.492188 44.103365, 7.998047 43.779027, 7.349854 45.390735, 7.119141 46.679594, 8.052979 47.894248, 8.701172 49.037868, 5.559082 50.035974, 2.252197 51.323747, 1.82373 51.193115))"

    def index
      gpx_segments = Gpx::Segment.select("id, gpx_track_id, status, ST_Intersection(geom, ST_GeomFromText('#{FRANCE}', 4326)) AS geom")
        .where("ST_Intersects(geom, ST_GeomFromText('#{FRANCE}', 4326))")

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
  end
end

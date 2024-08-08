module Api
  class TrainLinesController < ApplicationController
    caches_action :index

    def index
      @train_lines = simplified_train_lines

      render json: {
        type: "FeatureCollection",
        features: @train_lines.map do |line|
          {
            type: "Feature",
            geometry: RGeo::GeoJSON.encode(line.geom)
          }
        end
      }
    end

    private

    def simplified_train_lines
      TrainLine.all.select("ST_Simplify(geom, 0.001) as geom")
    end
  end
end

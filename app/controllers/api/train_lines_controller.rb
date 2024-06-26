module Api
  class TrainLinesController < ApplicationController
    caches_action :index

    def index
      @train_lines = TrainLine.all

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
  end
end

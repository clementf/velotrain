module Api
  class TrainStationsController < ApplicationController
    def index
      @train_stations = TrainStation.all

      render json: {
        type: "FeatureCollection",
        features: @train_stations.map do |station|
          {
            type: "Feature",
            geometry: RGeo::GeoJSON.encode(station.lonlat),
            properties: {
              name: station.name,
              code: station.code
            }
          }
        end
      }
    end
  end
end

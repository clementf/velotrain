module Api
  class TrainStationsController < ApplicationController
    caches_action :index

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

    def show
      @train_station = Gtfs::Stop.train_stations.find_by("lower(name) = ?", params[:id].downcase)

      if @train_station.nil?
        render json: {error: "Train station not found"}, status: :not_found
        return
      end

      render json: {
        name: @train_station.name,
        lines: @train_station.stop_times.preload(:route).map(&:route).uniq.group_by(&:short_name).map do |short_name, routes|
          {
            short_name: short_name,
            long_name: routes.first.long_name,
            text_color: routes.first.text_color || "FFFFFF",
            bg_color: routes.first.bg_color || "000000"
          }
        end
      }
    end
  end
end

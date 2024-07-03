module Api
  class TripsController < ApplicationController
    def show
      stop_ids = params[:stop_ids].split(",").map(&:to_i)
      path = []
      longitudes = []
      latitudes = []
      stop_ids.each_cons(2) do |from, to|
        from_stop = Gtfs::Stop.find(from)
        to_stop = Gtfs::Stop.find(to)

        longitudes << from_stop.geom.x
        latitudes << from_stop.geom.y
        longitudes << to_stop.geom.x
        latitudes << to_stop.geom.y

        path << JSON.parse(TrainLinePath.new(from_stop, to_stop).find_path)
      end

      bounds =
        [
          [longitudes.min, latitudes.min],
          [longitudes.max, latitudes.max]
        ]

      render json: {
        path: path,
        bounds: bounds
      }
    end
  end
end

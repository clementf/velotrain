module Api
  class TripsController < ApplicationController
    def index
      router = Routing::Router.get

      from = Gtfs::Stop.find_by(id: params[:from_stop_id])
      to = Gtfs::Stop.find_by(id: params[:to_stop_id])

      if from.nil? || to.nil?
        @results = []
        render "trips/index", status: :bad_request
        return
      end

      parsed_hour_from_params = begin
        ActiveSupport::TimeZone["Europe/Paris"].parse(params["hour"] + ":" + params["minute"])
      rescue
        nil
      end

      # generate shortest path for now, and the next 4 possible trains
      @results = []

      4.times do
        start_time = (@results.last&.dig(:path, 0, :departure_time)&.+ 1.minutes) || parsed_hour_from_params || Time.current

        result = router.shortest_path(from, to, start_time.utc.strftime("%H:%M:%S"))
        break if result[:path].empty?

        @results << result
      end

      @stop_ids = @results.first[:path].flatten.map { |segment| segment[:to] }.prepend(@results.first[:start]).join(",") if @results.any?
      render "trips/index"
    end

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

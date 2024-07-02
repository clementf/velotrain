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
        ActiveSupport::TimeZone["Europe/Paris"].parse(params["[departure_time(4i)]"] + ":" + params["[departure_time(5i)]"])
      rescue
        nil
      end

      # generate shortest path for now, in +1 hour, in +2 hours and in +4 hours
      @results = []
      [0, 1, 2, 4].each do |hours|
        hour = parsed_hour_from_params || Time.current
        result = router.shortest_path(from, to, (hour + hours.hours).utc.strftime("%H:%M:%S"))
        @results << result if result[:path].present? && @results.none? { |r| r[:path] == result[:path] }
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

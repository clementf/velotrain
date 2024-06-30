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

      # generate shortest path for now, in +1 hour, in +2 hours and in +4 hours
      @results = []
      [0, 1, 2, 4].each do |hours|
        result = router.shortest_path(from, to, (Time.current + hours.hours).strftime("%H:%M:%S"))
        @results << result if result[:path].present? && @results.none? { |r| r[:path] == result[:path] }
      end

      render "trips/index"
    end

    def show
      stop_ids = params[:stop_ids].split(",").map(&:to_i)
      path = []
      stop_ids.each_cons(2) do |from, to|
        from_stop = Gtfs::Stop.find(from)
        to_stop = Gtfs::Stop.find(to)

        path << JSON.parse(TrainLinePath.new(from_stop, to_stop).find_path)
      end

      render json: path
    end
  end
end

module Api
  class TripsController < ApplicationController
    def index
      router = Routing::Router.get

      from = Gtfs::Stop.find(params[:from_stop_id])
      to = Gtfs::Stop.find(params[:to_stop_id])

      if from.nil? || to.nil?
        render json: {error: "Invalid from or to stop"}, status: :bad_request
        return
      end

      @result = router.shortest_path(from, to, Time.current.strftime("%H:%M:%S"))

      if @result[:path].blank?
        @result = router.shortest_path(from, to, "00:00:00")
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

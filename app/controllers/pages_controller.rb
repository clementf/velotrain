class PagesController < ApplicationController
  def home
    router = Routing::Router.get

    @from = Gtfs::Stop.find_by(id: params[:from_stop_id])
    @to = Gtfs::Stop.find_by(id: params[:to_stop_id])

    if @from.nil? || @to.nil?
      @results = []
      render "pages/home"
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

      result = router.shortest_path(@from, @to, start_time.utc.strftime("%H:%M:%S"))
      break if result[:path].empty?

      @results << result
    end

    @stop_ids = @results.first[:path].flatten.map { |segment| segment[:to] }.prepend(@results.first[:start]).join(",") if @results.any?
  end
end

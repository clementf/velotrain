class PagesController < ApplicationController
  def home
    router = Routing::SncfApiRouter.new

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

    @results = router.paths(@from, @to, datetime: parsed_hour_from_params)
  end
end

class PagesController < ApplicationController
  def home
  end

  def map
    router = Routing::SncfApiRouter.new

    @from = TrainStation.find_by(id: params[:from_stop_id])
    @to = TrainStation.find_by(id: params[:to_stop_id])

    if @from.nil? || @to.nil?
      @results = []
      return
    end

    parsed_hour_from_params = begin
      ActiveSupport::TimeZone["Europe/Paris"].parse(params["hour"] + ":00")
    rescue
      nil
    end

    # default to 8:00 if no hour is provided
    if parsed_hour_from_params.nil?
      parsed_hour_from_params = ActiveSupport::TimeZone["Europe/Paris"].parse("08:00")
    end

    saved_search = SavedSearch.find_or_initialize_by(from_stop: @from.gtfs_stop, to_stop: @to.gtfs_stop, datetime: parsed_hour_from_params)
    if saved_search.persisted?
      @results = saved_search.results.map { |result| result.with_indifferent_access }
    else
      @results = router.paths(@from, @to, datetime: parsed_hour_from_params)
      saved_search.results = @results
    end

    saved_search.searches_count += 1
    saved_search.save
  end

  def about
  end
end

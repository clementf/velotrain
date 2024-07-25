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
      ActiveSupport::TimeZone["Europe/Paris"].parse(params["hour"] + ":00")
    rescue
      nil
    end

    saved_search = SavedSearch.find_or_initialize_by(from_stop: @from, to_stop: @to, datetime: parsed_hour_from_params)
    if saved_search.persisted?
      @results = saved_search.results.map { |result| result.with_indifferent_access }
    else
      @results = router.paths(@from, @to, datetime: parsed_hour_from_params)
      saved_search.results = @results
    end

    saved_search.searches_count += 1
    saved_search.save
  end
end

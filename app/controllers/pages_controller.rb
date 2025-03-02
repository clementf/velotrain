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

    # Parse the date from params or use current date
    selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Make sure date is not in the past
    selected_date = Date.current if selected_date < Date.current

    # Make sure date is not more than 2 months in the future
    selected_date = Date.current + 2.months if selected_date > Date.current + 2.months

    parsed_hour_from_params = begin
      hour_value = params["hour"].presence || "08"
      ActiveSupport::TimeZone["Europe/Paris"].parse("#{selected_date.to_s} #{hour_value}:00")
    rescue
      ActiveSupport::TimeZone["Europe/Paris"].parse("#{selected_date.to_s} 08:00")
    end

    saved_search = SavedSearch.find_or_initialize_by(
      from_stop: @from.gtfs_stop,
      to_stop: @to.gtfs_stop,
      datetime: parsed_hour_from_params
    )

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

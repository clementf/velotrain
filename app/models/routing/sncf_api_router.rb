require 'net/http'

module Routing
  class SncfApiRouter
    def paths(from, to, datetime: Time.current, min_nb_journeys: 2)
      @min_nb_journeys = min_nb_journeys
      @datetime = datetime
      @max_nb_journeys = 4

      set_from_and_to(from, to)

      journeys = standard_journeys = format_response(make_request)
      if standard_journeys.none? { |journey| journey[:transfers] == 0 } && standard_journeys.none? { |journey| journey[:duration] < 3.hours }
        journeys += journeys_by_paris.flatten
      end

      # journeys too long (over 20 hrs) are not relevant
      if journeys.any? { |journey| journey[:duration] < 20.hours }
        journeys = journeys.select { |journey| journey[:duration] < 20.hours }
      end

      journeys.sort_by { |journey| [journey[:duration]] }
    end

    private

    def journeys_by_paris
      journeys_to_paris = format_response(make_request(url_to_paris))

      journeys_to_paris.map do |journey|
        time_after_connection = journey[:arrival_time] + 1.5.hours
        journeys_from_paris = format_response(make_request(api_url(from: "admin:fr:75056", to: "stop_area:SNCF:#{@to}", datetime: time_after_connection)))
        journeys_from_paris.map do |journey_from_paris|
          {
            departure_time: journey[:departure_time],
            arrival_time: journey_from_paris[:arrival_time],
            duration: journey_from_paris[:arrival_time] - journey[:departure_time],
            transfers: journey[:transfers] + journey_from_paris[:transfers] + 1,
            sections: journey[:sections] + journey_from_paris[:sections]
          }
        end
      end
    end

    def make_request(url = api_url())
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = Rails.application.credentials.sncf_api_key

      Rails.logger.debug("URL: #{url}")

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
    end

    def set_from_and_to(from, to)
      if from.is_a?(String) && to.is_a?(String)
        @from = Gtfs::Stop.train_stations.find_by!(name: from).area_id
        @to = Gtfs::Stop.train_stations.find_by!(name: to).area_id
      end

      if from.is_a?(Gtfs::Stop) && to.is_a?(Gtfs::Stop)
        @from = from.area_id
        @to = to.area_id
      end
    end

    def format_response(response)
      paris_time_zone = ActiveSupport::TimeZone["Europe/Paris"]
      JSON.parse(response.body).fetch("journeys", []).map do |journey|
        {
          departure_time: paris_time_zone.parse(journey.dig("departure_date_time")),
          arrival_time: paris_time_zone.parse(journey.dig("arrival_date_time")),
          duration: journey.dig("duration"),
          transfers: journey.dig("nb_transfers"),
          sections: journey.dig("sections").select { |section| section.dig("type") == "public_transport" }.map do |section|
            {
              from: section.dig("from", "stop_point", "name"),
              to: section.dig("to", "stop_point", "name"),
              route: section.dig("display_informations", "label"),
              departure_time: paris_time_zone.parse(section.dig("departure_date_time")),
              arrival_time: paris_time_zone.parse(section.dig("arrival_date_time")),
              duration: section.dig("duration"),
              commercial_mode: section.dig("display_informations", "commercial_mode"),
              geojson: section.dig("geojson"),
              stops: section.dig("stop_date_times").map do |stop|
                {
                  name: stop.dig("stop_point", "name"),
                  arrival_time: paris_time_zone.parse(stop.dig("arrival_date_time")),
                  departure_time: paris_time_zone.parse(stop.dig("departure_date_time"))
                }
              end
            }
          end
        }
      end.sort_by { |journey| journey[:departure_time] }
    end

    def url_to_paris
      api_url(from: "stop_area:SNCF:#{@from}", to: "admin:fr:75056", min_nb_journeys: 1, max_nb_journeys: 2)
    end

    def url_from_paris
      api_url(from: "admin:fr:75056", to: "stop_area:SNCF:#{@to}")
    end

    def api_url(from: nil, to: nil, datetime: @datetime, min_nb_journeys: @min_nb_journeys, max_nb_journeys: @max_nb_journeys)
      datetime = datetime.strftime("%Y%m%dT%H%M%S")

      if from.blank?
        from = "stop_area:SNCF:#{@from}"
      end
      if to.blank?
        to = "stop_area:SNCF:#{@to}"
      end

      "https://api.sncf.com/v1/coverage/sncf/journeys?from=#{from}&to=#{to}&datetime=#{datetime}&#{allowed_ids}&min_nb_journeys=#{min_nb_journeys}&max_nb_journeys=#{max_nb_journeys}&forbidden_uris[]=physical_mode:Coach"
    end

    # list of networks: https://api.sncf.com/v1/coverage/sncf/networks
    def allowed_ids
      "allowed_id[]=network:SNCF:IC&allowed_id[]=network:SNCF:TER&allowed_id[]=network:SNCF:ICN&allowed_id[]=network:SNCF:OUIGO_TC&allowed_id[]=network:SNCF:TERGV&allowed_id[]=network:SNCF:FR:Branding::6dfb1ec4-50b5-42a8-a531-a792b1ea6f2e:&allowed_id[]=network:SNCF:FR:Branding::5c5f14b9-bff2-4f94-8853-0f621bf1a1cf:&allowed_id[]=physical_mode:Bike"
    end
  end
end

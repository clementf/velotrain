require 'net/http'

module Routing
  class SncfApiRouter
    def paths(from, to, datetime: Time.current, min_nb_journeys: 4)
      @min_nb_journeys = min_nb_journeys
      @datetime = datetime.strftime("%Y%m%dT%H%M%S")

      set_from_and_to(from, to)

      format_response(make_request)
    end

    private

    def make_request
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

    def url
      "https://api.sncf.com/v1/coverage/sncf/journeys?from=stop_area:SNCF:#{@from}&to=stop_area:SNCF:#{@to}&datetime=#{@datetime}&#{allowed_ids}&min_nb_journeys=#{@min_nb_journeys}"
    end

    # list of networks: https://api.sncf.com/v1/coverage/sncf/networks
    def allowed_ids
      "allowed_id[]=network:SNCF:IC&allowed_id[]=network:SNCF:TER&allowed_id[]=network:SNCF:ICN&allowed_id[]=network:SNCF:OUIGO_TC&allowed_id[]=network:SNCF:TERGV&allowed_id[]=network:SNCF:FR:Branding::6dfb1ec4-50b5-42a8-a531-a792b1ea6f2e:&allowed_id[]=network:SNCF:FR:Branding::5c5f14b9-bff2-4f94-8853-0f621bf1a1cf:&allowed_id[]=physical_mode:Bike"
    end
  end
end

require 'net/http'
require 'rgeo/geo_json'

module Routing
  class SncfApiRouter
    ALLOWED_NETWORKS = {
      ic: "network:SNCF:IC",
      ter: "network:SNCF:TER",
      icn: "network:SNCF:ICN",
      ouigo: "network:SNCF:OUIGO_TC",
      tergv: "network:SNCF:TERGV",
      aleop: "network:SNCF:FR:Branding::e6a26019-486f-48d6-bb07-c24cae7fc307:",
      breizhgo: "network:SNCF:FR:Branding::7500b3d5-ea82-4597-ad48-edd896ca9ed0:",
      fluo: "network:SNCF:FR:Branding::c33db331-f39b-4e39-965d-053331becc07:",
      lex: "network:SNCF:FR:Branding::a80c322c-12b1-4273-9413-e2df5dd6dce8:",
      mobigo: "network:SNCF:FR:Branding::fa03c60c-432a-4c27-b646-e231f19253c6:",
      nomad: "network:SNCF:FR:Branding::3b6b9052-6f3e-4ea4-866f-3bd913db6b22:",
      regionaura: "network:SNCF:FR:Branding::f4fa116c-2d6a-4696-b6c9-47195206d6f4:",
      remi: "network:SNCF:FR:Branding::d5d601cf-e383-4138-8e70-ee1b7fcadd48:",
      remi_exp: "network:SNCF:FR:Branding::8c1ce319-d566-4575-a416-a46730280ce5:",
      solea: "network:SNCF:FR:Branding::45d07532-11f7-4837-98b7-cae82b0ab0c4:",
      ter_hdf: "network:SNCF:FR:Branding::6dfb1ec4-50b5-42a8-a531-a792b1ea6f2e:",
      ter_na: "network:SNCF:FR:Branding::5c5f14b9-bff2-4f94-8853-0f621bf1a1cf:",
      zou: "network:SNCF:FR:Branding::6e0a3931-d3d3-4576-a37a-b133fac0dd44:",
      liO: "network:SNCF:FR:Branding::d504b7a9-d7b5-4b8d-951e-93edc254e41b:",
      transilien: "network:SNCF:TN",
      bike: "physical_mode:Bike"
    }.freeze

    def paths(from, to, datetime: Time.current, min_nb_journeys: 1)
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
        @from = TrainStation.find_by!(name: from).area_id
        @to = TrainStation.find_by!(name: to).area_id
      end

      if from.is_a?(TrainStation) && to.is_a?(TrainStation)
        @from = from.area_id
        @to = to.area_id
      end
    end

    def format_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("SNCF API error: #{response.body}, #{response.code}")
        return []
      end

      Rails.logger.debug("SNCF API response: #{response.body}")

      paris_time_zone = ActiveSupport::TimeZone["Europe/Paris"]
      JSON.parse(response.body).fetch("journeys", []).map do |journey|
        {
          departure_time: paris_time_zone.parse(journey.dig("departure_date_time")),
          arrival_time: paris_time_zone.parse(journey.dig("arrival_date_time")),
          duration: journey.dig("duration"),
          transfers: journey.dig("nb_transfers"),
          sections: journey.dig("sections").select { |section| section.dig("type") == "public_transport" }.map do |section|
            commercial_mode = section.dig("display_informations", "commercial_mode")
            geojson = section.dig("geojson")

            bike_rules = find_bike_rules_for_section(section) if has_relevant_bike_rules?(section)

            {
              from: section.dig("from", "stop_point", "name"),
              to: section.dig("to", "stop_point", "name"),
              route: section.dig("display_informations", "label"),
              departure_time: paris_time_zone.parse(section.dig("departure_date_time")),
              arrival_time: paris_time_zone.parse(section.dig("arrival_date_time")),
              duration: section.dig("duration"),
              commercial_mode: commercial_mode,
              geojson: geojson,
              bike_rules: bike_rules,
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

    def find_bike_rules_for_section(section)
      return [] unless geojson = section.dig("geojson")

      # First try to find a matching rule based on network code
      if commercial_mode = section.dig("display_informations", "commercial_mode").parameterize
        network_rule = Area.joins(:regional_bike_rule)
                          .where("regional_bike_rules.network_code = ?", commercial_mode)
                          .includes(:regional_bike_rule)
                          .first

        if network_rule
          return [{
            region_name: network_rule.name,
            source_url: network_rule.regional_bike_rule.source_url,
            extracted_information: network_rule.regional_bike_rule.extracted_information,
            bike_always_allowed: network_rule.regional_bike_rule.bike_always_allowed_without_booking
          }]
        end
      end

      # Fallback to geographical intersection if no network match
      intersecting_areas = Area.joins(:regional_bike_rule)
                              .where("ST_Intersects(geom, ST_GeomFromGeoJSON(?))", geojson.to_json)
                              .includes(:regional_bike_rule)

      intersecting_areas.map do |area|
        {
          region_name: area.name,
          source_url: area.regional_bike_rule.source_url,
          extracted_information: area.regional_bike_rule.extracted_information,
          bike_always_allowed: area.regional_bike_rule.bike_always_allowed_without_booking
        }
      end
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

    # list of networks: https://api.sncf.com/v1/coverage/sncf/networks (username is api key, pwd is empty)
    def allowed_ids
      ALLOWED_NETWORKS.values
        .map { |id| "allowed_id[]=#{id}" }
        .join("&")
    end

    def has_relevant_bike_rules?(section)
      !section.dig("display_informations", "commercial_mode").match?(/OUIGO|ICN|Intercités/)
    end
  end
end
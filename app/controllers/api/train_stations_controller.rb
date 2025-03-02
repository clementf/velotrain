module Api
  class TrainStationsController < ApplicationController
    caches_action :index

    def index
      @train_stations = TrainStation.all

      render json: {
        type: "FeatureCollection",
        features: @train_stations.map do |station|
          {
            type: "Feature",
            geometry: RGeo::GeoJSON.encode(station.lonlat),
            properties: {
              name: station.name,
              code: station.code,
              drg: station.drg
            }
          }
        end
      }
    end

    def search
      query = params[:q].to_s.downcase

      if query.blank?
        @train_stations = TrainStation.limit(10).order("drg ASC, name ASC")
      else
        # Phase 1: Accent-insensitive exact matching
        exact_matches = TrainStation.where("unaccent(lower(name)) LIKE unaccent(?)", "%#{query}%")
                                   .limit(10)
                                   .order("drg ASC, name ASC")

        # If we have enough exact matches, use them
        if exact_matches.count >= 2
          @train_stations = exact_matches
        else
          # Phase 2: Combine full-text search and trigram similarity
          # Prepare query for full-text search
          query_terms = query.split.map { |term| "#{term}:*" }.join(" & ")

          @train_stations = TrainStation
            .where("
              unaccent(lower(name)) LIKE unaccent(?) OR
              to_tsvector('french', unaccent(lower(name))) @@ to_tsquery('french', unaccent(?)) OR
              similarity(unaccent(lower(name)), unaccent(?)) > 0.3
            ", "%#{query}%", query_terms, query)
            .order(Arel.sql("
              CASE
                WHEN unaccent(lower(name)) LIKE unaccent('%#{ActiveRecord::Base.connection.quote_string(query)}%') THEN 0
                WHEN to_tsvector('french', unaccent(lower(name))) @@ to_tsquery('french', unaccent('#{ActiveRecord::Base.connection.quote_string(query_terms)}')) THEN 1
                ELSE 2
              END,
              similarity(unaccent(lower(name)), unaccent('#{ActiveRecord::Base.connection.quote_string(query)}')) DESC,
              drg ASC,
              name ASC
            "))
            .limit(10)
        end
      end

      render turbo_stream: helpers.async_combobox_options(@train_stations)
    end

    def show
      @train_station = Gtfs::Stop.train_stations.find_by("lower(name) = ?", params[:id].downcase)

      if @train_station.nil?
        render json: {error: "Train station not found"}, status: :not_found
        return
      end

      render json: {
        name: @train_station.name,
        trains_per_day: @train_station.trains_per_day,
        lines: @train_station.stop_times.preload(:route).map(&:route).uniq.group_by(&:short_name).map do |short_name, routes|
          {
            short_name: short_name,
            long_name: routes.first.long_name,
            text_color: routes.first.text_color || "FFFFFF",
            bg_color: routes.first.bg_color || "000000"
          }
        end
      }
    end

    def isochrones
      @train_station = TrainStation.find_by(code: params[:code])

      if @train_station.nil?
        render json: { error: "Train station not found" }, status: :not_found
        return
      end

      render json: {
        type: "FeatureCollection",
        features: @train_station.isochrones.map do |isochrone|
          {
            type: "Feature",
            geometry: RGeo::GeoJSON.encode(isochrone.geom),
            properties: {
              range: isochrone.range
            }
          }
        end
      }
    end
  end
end

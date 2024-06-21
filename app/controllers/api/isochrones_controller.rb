module Api
  class IsochronesController < ApplicationController
    caches_action :index, cache_path: proc { |c| "isochrones/#{c.params[:zoom]}/#{c.params[:range]}" }

    def index
      if params[:zoom].present? && params[:range].present?
        zoom_level = params[:zoom].to_f
        range_in_seconds = params[:range].to_i

        simplification_sql_clause = if zoom_level < 10.0
          "ST_Simplify(ST_Union(geom), 0.005)"
        else
          "ST_Union(geom)"
        end

        sql = <<~SQL
          SELECT row_to_json(fc)
          FROM (
            SELECT 'FeatureCollection' AS type, array_to_json(array_agg(f)) AS features
            FROM (
              SELECT 'Feature' AS type,
                     ST_AsGeoJSON(#{simplification_sql_clause})::json AS geometry
              FROM isochrones
              WHERE range = #{range_in_seconds}
            ) AS f
          ) as fc;
        SQL

        rows = ActiveRecord::Base.connection.execute(sql)

        render json: JSON.parse(rows[0]["row_to_json"])
      else
        render json: {error: "zoom_level and range_in_seconds are required"}, status: :bad_request
      end
    end
  end
end

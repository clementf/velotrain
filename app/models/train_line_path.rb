class TrainLinePath
  def initialize(start_stop, end_stop)
    @start_lon, @start_lat = start_stop.geom.coordinates
    @end_lon, @end_lat = end_stop.geom.coordinates
    @from_lon, @from_lat = start_stop.geom.coordinates
    @to_lon, @to_lat = end_stop.geom.coordinates
  end

  def find_path
    find_approx_path
  end

  def find_approx_path
    sql = <<-SQL
    WITH input_points AS (
        SELECT
            'Point 1' AS name,
            ST_SetSRID(ST_MakePoint(#{@from_lon}, #{@from_lat}), 4326) AS geom
        UNION ALL
        SELECT
            'Point 2' AS name,
            ST_SetSRID(ST_MakePoint(#{@to_lon}, #{@to_lat}), 4326) AS geom
    )

    SELECT
        ST_AsGeoJSON(ST_MakeLine(p.geom ORDER BY p.name)) AS geojson
    FROM
        input_points p;
    SQL

    result = ActiveRecord::Base.connection.execute(sql)
    result.first["geojson"]
  end
end

class TrainStation < ApplicationRecord
  attribute :lonlat, :st_point, geographic: true, srid: 4326

  def lon
    lonlat.x
  end

  def lat
    lonlat.y
  end
end

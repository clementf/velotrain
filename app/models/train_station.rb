class TrainStation < ApplicationRecord
  attribute :lonlat, :st_point, geographic: true

  def lon
    lonlat.x
  end

  def lat
    lonlat.y
  end
end

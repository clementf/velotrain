class Isochrone < ApplicationRecord
  validates_uniqueness_of :range, scope: :center

  attribute :center, :st_point, geographic: true, srid: 4326
end

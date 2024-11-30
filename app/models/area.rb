class Area < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :geom, presence: true

  before_validation :set_code

  def self.from_geojson_url(url)
    response = HTTP.get(url)
    raise "Failed to fetch GeoJSON" unless response.status.success?

    geojson = JSON.parse(response.body.to_s)
    RGeo::GeoJSON.decode(geojson).geometry
  end

  private

  def set_code
    self.code = name.parameterize
  end
end 

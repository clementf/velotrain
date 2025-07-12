class Accommodation < ApplicationRecord
  has_many :outbound_clicks, dependent: :destroy
  
  serialize :images, coder: JSON

  validates :name, presence: true
  validates :source, presence: true
  validates :external_id, presence: true
  validates :coordinates, presence: true
  validates :external_id, uniqueness: { scope: :source }

  scope :within_bounds, ->(bounds) {
    southwest_lng, southwest_lat, northeast_lng, northeast_lat = bounds
    where(
      "ST_Within(coordinates, ST_MakeEnvelope(?, ?, ?, ?, 4326))",
      southwest_lng, southwest_lat, northeast_lng, northeast_lat
    )
  }

  def longitude
    coordinates&.x
  end

  def latitude
    coordinates&.y
  end
end

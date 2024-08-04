class Gpx::Track < ApplicationRecord
  has_many :segments, class_name: "Gpx::Segment", dependent: :destroy, foreign_key: :gpx_track_id
end

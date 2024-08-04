class Gpx::Segment < ApplicationRecord
  belongs_to :track, class_name: "Gpx::Track", foreign_key: :gpx_track_id
end

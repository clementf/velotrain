class Gpx::Track < ApplicationRecord
  has_many :segments, class_name: "Gpx::Segment", dependent: :destroy, foreign_key: :gpx_track_id

  has_one_attached :file

  after_save :process_file_if_changed

  def distance_km
    Rails.cache.fetch("#{cache_key_with_version}/distance_km") do
      segments.sum(&:distance_km)
    end
  end

  def process_file_if_changed
    if attachment_changes["file"].present?
      GpxTrackProcessJob.perform_later(id)
    end
  end
end

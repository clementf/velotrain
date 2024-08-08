class GpxTrackProcessJob < ApplicationJob
  def perform(track_id)
    track = Gpx::Track.find(track_id)
    GpxImport.new(track.file.download, track).import_track_from_file
  end
end

class AccommodationSyncJob < ApplicationJob
  def perform
    ToplocService.fetch_and_sync_accommodations
  end
end
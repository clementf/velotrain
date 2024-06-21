class AddServiceIdToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :gtfs_trips, :service_id, :string
  end
end

class CreateGtfsServiceDates < ActiveRecord::Migration[7.1]
  def change
    create_table :gtfs_service_dates do |t|
      t.string :service_id
      t.date :date

      t.timestamps
    end
    add_index :gtfs_service_dates, :service_id
  end
end

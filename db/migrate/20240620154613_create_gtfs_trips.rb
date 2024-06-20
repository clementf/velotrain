class CreateGtfsTrips < ActiveRecord::Migration[7.1]
  def change
    create_table :gtfs_trips do |t|
      t.belongs_to :gtfs_route, null: false, foreign_key: true
      t.string :code

      t.timestamps
    end
  end
end

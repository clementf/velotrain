class CreateGtfsRoutes < ActiveRecord::Migration[7.1]
  def change
    create_table :gtfs_routes do |t|
      t.string :code
      t.string :short_name
      t.string :long_name
      t.string :bg_color
      t.string :text_color

      t.timestamps
    end
  end
end

class CreateIsochrones < ActiveRecord::Migration[7.1]
  def change
    create_table :isochrones do |t|
      t.geometry :geom
      t.st_point :center
      t.integer :range

      t.timestamps
    end
  end
end

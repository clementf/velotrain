class CreateTrainStations < ActiveRecord::Migration[7.1]
  def change
    create_table :train_stations do |t|
      t.string :name
      t.string :code
      t.st_point :lonlat

      t.timestamps
    end
  end
end

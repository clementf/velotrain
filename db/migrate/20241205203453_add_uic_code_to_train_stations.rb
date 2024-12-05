class AddUicCodeToTrainStations < ActiveRecord::Migration[7.1]
  def change
    add_column :train_stations, :uic_code, :string
  end
end

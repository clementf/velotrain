class AddDrgToTrainStations < ActiveRecord::Migration[7.1]
  def change
    add_column :train_stations, :drg, :string
  end
end

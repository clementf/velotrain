class AddPostgisIndices < ActiveRecord::Migration[7.1]
  def change
    add_index :train_stations, :lonlat, using: :gist
    add_index :isochrones, :center, using: :gist
  end
end

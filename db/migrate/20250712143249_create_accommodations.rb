class CreateAccommodations < ActiveRecord::Migration[7.1]
  def change
    create_table :accommodations do |t|
      t.string :accommodation_type
      t.string :source
      t.st_point :coordinates, srid: 4326
      t.string :name
      t.string :city
      t.string :zip_code
      t.decimal :price, precision: 10, scale: 2
      t.string :url
      t.string :external_id
      t.text :images

      t.timestamps
    end

    add_index :accommodations, :coordinates, using: :gist
    add_index :accommodations, [:source, :external_id], unique: true
  end
end

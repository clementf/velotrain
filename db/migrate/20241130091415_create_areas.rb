class CreateAreas < ActiveRecord::Migration[7.1]
  def change
    create_table :areas do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.geometry :geom, srid: 4326

      t.timestamps

      t.index :code, unique: true
    end
  end
end
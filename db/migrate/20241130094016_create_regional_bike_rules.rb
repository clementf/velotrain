class CreateRegionalBikeRules < ActiveRecord::Migration[7.1]
  def change
    create_table :regional_bike_rules do |t|
      t.references :area, null: false, foreign_key: true
      t.string :source_url
      t.boolean :bike_always_allowed_without_booking, default: false
      t.text :extracted_information

      t.timestamps
    end
  end
end
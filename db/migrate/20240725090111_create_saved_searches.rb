class CreateSavedSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :saved_searches do |t|
      t.references :from_stop, null: false, foreign_key: { to_table: :gtfs_stops }
      t.references :to_stop, null: false, foreign_key: { to_table: :gtfs_stops }
      t.datetime :datetime, null: false
      t.jsonb :results, null: false, default: []
      t.bigint :searches_count, null: false, default: 0
      t.timestamps
    end
  end
end

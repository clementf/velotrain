class CreateOutboundClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :outbound_clicks do |t|
      t.references :accommodation, null: false, foreign_key: true

      t.timestamps
    end
  end
end

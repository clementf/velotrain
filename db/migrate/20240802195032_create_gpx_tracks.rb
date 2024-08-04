class CreateGpxTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :gpx_tracks do |t|
      t.string :name

      t.timestamps
    end
  end
end

class CreateGpxSegments < ActiveRecord::Migration[7.1]
  def change
    create_table :gpx_segments do |t|
      t.belongs_to :gpx_track, null: false, foreign_key: true
      t.string :status
      t.line_string :geom, geographic: true, has_z: true

      t.timestamps
    end
  end
end

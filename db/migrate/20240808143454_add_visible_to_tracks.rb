class AddVisibleToTracks < ActiveRecord::Migration[7.1]
  def change
    add_column :gpx_tracks, :visible, :boolean, default: true, null: false
  end
end

class AddDistanceToSegments < ActiveRecord::Migration[7.1]
  def change
    add_column :gpx_segments, :distance, :integer
  end
end

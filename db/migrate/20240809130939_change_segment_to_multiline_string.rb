class ChangeSegmentToMultilineString < ActiveRecord::Migration[7.1]
  def change
    # truncate the table
    Gpx::Segment.delete_all
    Gpx::Track.delete_all
    change_column :gpx_segments, :geom, :multi_line_string, geographic: true
  end
end

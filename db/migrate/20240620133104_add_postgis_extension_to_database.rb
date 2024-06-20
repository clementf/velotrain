class AddPostgisExtensionToDatabase < ActiveRecord::Migration[7.1]
  def change
    enable_extension "postgis"
  end
end

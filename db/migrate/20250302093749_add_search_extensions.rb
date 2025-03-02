class AddSearchExtensions < ActiveRecord::Migration[7.1]
  def change
    enable_extension "unaccent"
    enable_extension "pg_trgm"
  end
end

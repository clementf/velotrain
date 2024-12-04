class AddNetworkCodeToRegionalBikeRules < ActiveRecord::Migration[7.1]
  def change
    add_column :regional_bike_rules, :network_code, :string
  end
end

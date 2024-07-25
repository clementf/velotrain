class SavedSearch < ApplicationRecord
  belongs_to :from_stop, class_name: "Gtfs::Stop"
  belongs_to :to_stop, class_name: "Gtfs::Stop"
end

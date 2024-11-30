class RegionalBikeRule < ApplicationRecord
  belongs_to :area

  validates :area, presence: true
  validates :bike_always_allowed_without_booking, inclusion: { in: [true, false] }
end 
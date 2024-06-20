class Isochrone < ApplicationRecord
  validates_uniqueness_of :range, scope: :center
end

require "csv"

class Gtfs::Stop < ApplicationRecord
  STOP_CODES_WITHIN_PARIS = %w[
    StopArea:OCE87113001
    StopArea:OCE87271007
    StopArea:OCE87384008
    StopArea:OCE87391003
    StopArea:OCE87391102
    StopArea:OCE87547000
    StopArea:OCE87686006
    StopArea:OCE87686667
  ]

  belongs_to :parent_stop, class_name: "Gtfs::Stop", foreign_key: "parent_stop_id", optional: true, inverse_of: :children
  has_many :children, class_name: "Gtfs::Stop", foreign_key: "parent_stop_id", dependent: :destroy, inverse_of: :parent_stop
  has_many :stop_times, class_name: "Gtfs::StopTime", foreign_key: "gtfs_stop_id"

  has_many :saved_searches_from, class_name: "SavedSearch", foreign_key: "from_stop_id", dependent: :destroy
  has_many :saved_searches_to, class_name: "SavedSearch", foreign_key: "to_stop_id", dependent: :destroy

  scope :train_stations, -> { where("gtfs_stops.code LIKE '%OCETrain%' OR gtfs_stops.code LIKE '%OCETramTrain%' OR gtfs_stops.code LIKE '%IDFM%'") }
  scope :bus_stops, -> { where("code LIKE '%OCECar%'") }
  scope :within_paris, -> { where(code: STOP_CODES_WITHIN_PARIS) }

  def self.train_station_by_name(name)
    train_stations.find_by("lower(name) = ?", name.downcase)
  end

  def trains_per_day(day: Date.today)
    todays_services = Gtfs::ServiceDate.where(date: day).pluck(:service_id)
    stop_times.joins(:trip).where(gtfs_trips: {service_id: todays_services}).count
  end

  def area_id
    if parent_stop.present?
      parent_stop.area_id
    else
      code.split(":").last.split("OCE").last
    end
  end

  def to_combobox_display
    name.to_s
  end

  def self.import(filepath, append: false)
    Gtfs::Stop.delete_all unless append

    Gtfs::Stop.transaction do
      # stop_id,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station
      CSV.foreach(filepath, headers: true) do |row|
        Gtfs::Stop.create!(
          code: row["stop_id"],
          name: row["stop_name"],
          geom: "POINT(#{row["stop_lon"]} #{row["stop_lat"]})",
          parent_stop_id: Gtfs::Stop.find_by(code: row["parent_station"])&.id
        )
      end
    end
  end
end

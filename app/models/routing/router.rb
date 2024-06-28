module Routing
  class Router
    def initialize
    end

    # returns the shortest path between the two stations, using a time dependent Dijkstra algorithm
    def shortest_path(from, to, time)
      if from.is_a?(String)
        from = Gtfs::Stop.train_stations.find_by!(name: from).id
      end
      if to.is_a?(String)
        to = Gtfs::Stop.train_stations.find_by!(name: to).id
      end

      dijkstra = TimeDependentDijkstra.new(graph)

      puts "Finding shortest path..."

      dijkstra.shortest_path(from, to, Time.parse("2024-06-21 #{time}"))
    end

    def graph
      return @graph if @graph

      @graph = TimeDependentGraph.new

      route_cache = Gtfs::Trip.pluck(:id, :gtfs_route_id).to_h

      day = Date.parse("2024-06-21")
      todays_services = Gtfs::ServiceDate.where(date: day).pluck(:service_id)
      stop_times = Gtfs::StopTime.order(:gtfs_trip_id).joins(:trip).where(gtfs_trips: {service_id: todays_services})

      puts "Building graph..."

      stop_times.pluck(:gtfs_trip_id, :departure_time, :arrival_time, :gtfs_stop_id).group_by { |trip_id, _, _| trip_id }.each do |trip_id, times|
        route_id = route_cache[trip_id]

        times.each_cons(2) do |from_stop_time, to_stop_time|
          @graph.add_edge(from_stop_time[3], to_stop_time[3], from_stop_time[1], to_stop_time[2], route_id)
        rescue ArgumentError => e
          puts "Error adding edge: #{e}, for times #{from_stop_time.departure_time} -> #{to_stop_time.arrival_time}"
        end
      end

      @graph
    end

    # useful for debugging / console usage
    def print_shortest_path(from, to, time)
      result = shortest_path(from, to, time)
      path = result[:path]
      last_segment = nil

      pretty_path = ""

      path.group_by { |segment| segment[:route_id] }.each do |route_id, segments|
        route = Gtfs::Route.find(route_id)
        pretty_path << "Route: #{route.long_name} \n"
        segments.each do |segment|
          stop_name = Gtfs::Stop.find(segment[:to]).name
          pretty_path << "  #{segment[:arrival_time].strftime("%H:%M")} - #{stop_name} \n"
          last_segment = segment
        end
      end

      puts pretty_path
    end
  end
end

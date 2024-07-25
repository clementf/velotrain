module Routing
  class TimeDependentGraph
    attr_accessor :graph

    def initialize
      @graph = Hash.new { |hash, key| hash[key] = [] }
    end

    def add_edge(from, to, departure_time, arrival_time, route_id)
      @graph[from] << {to: to, departure_time: departure_time, arrival_time: arrival_time, route_id: route_id}
    end

    def neighbors(node, current_time, current_route_id)
      reachable_stations(node, current_time, current_route_id) + transfers_within_paris(node, current_time)
    end

    private

    def reachable_stations(node, current_time, current_route_id)
      @graph[node].select do |edge|
        transfer_time_if_needed = (current_route_id.present? && current_route_id != edge[:route_id]) ? 15 * 60 : 0

        edge[:departure_time] >= current_time + transfer_time_if_needed
      end
    end

    def transfers_within_paris(node, current_time)
      return [] unless stations_in_paris.include?(node)

      paris_stations = @graph.keys.select { |station| stations_in_paris.include?(station) }

      paris_stations.map do |paris_station|
        {to: paris_station, departure_time: current_time, arrival_time: current_time + 60 * 60, route_id: nil}
      end
    end

    def stations_in_paris
      @stations_in_paris ||= Gtfs::Stop.within_paris.pluck(:id)
    end
  end
end

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
      @graph[node].select do |edge|
        transfer_time_if_needed = (current_route_id != edge[:route_id]) ? 15 * 60 : 0

        edge[:departure_time] >= current_time + transfer_time_if_needed
      end
    end
  end
end

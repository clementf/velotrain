require "time"
require "set"

module Routing
  class TimeDependentDijkstra
    def initialize(graph)
      @graph = graph
    end

    def shortest_path(start, target, start_time)
      distances = Hash.new(Float::INFINITY)
      distances[start] = start_time
      priority_queue = Set.new([start])

      arrival_times = {start => start_time}
      previous_stops = {}
      trip_details = {}

      until priority_queue.empty?
        current = priority_queue.min_by { |node| arrival_times[node] }
        priority_queue.delete(current)

        break if current == target

        current_route_id = if trip_details[current]
          trip_details[current][:route_id]
        end

        current_time = arrival_times[current]

        @graph.neighbors(current, current_time, current_route_id).each do |edge|
          new_arrival_time = edge[:arrival_time]
          if distances[edge[:to]] == Float::INFINITY || new_arrival_time < distances[edge[:to]]
            distances[edge[:to]] = new_arrival_time
            arrival_times[edge[:to]] = new_arrival_time
            priority_queue.add(edge[:to])

            previous_stops[edge[:to]] = current
            trip_details[edge[:to]] = edge
          end
        end
      end

      # Reconstruct the path
      path = []
      current = target
      while current != start
        path.unshift(trip_details[current].merge({from: previous_stops[current]}))
        current = previous_stops[current]
      end

      {
        start_time: start_time,
        arrival_time: distances[target],
        start: start,
        target: target,
        path: path
      }
    end
  end
end

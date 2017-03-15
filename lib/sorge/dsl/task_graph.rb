module Sorge
  class DSL
    class TaskGraph
      Edge = Struct.new(:head, :tail, :opts)

      def initialize(dsl)
        @dsl = dsl
        @matrix = Hash.new { |hash, key| hash[key] = {} }
      end

      def add(task)
        task.predecessors.each do |u, opts|
          @matrix[u.name][task.name] = Edge[u, task, opts]
        end
      end

      def successor_edges(task)
        @matrix[task.name].map { |_, edge| edge }
      end

      def successors(task)
        successor_edges(task).map(&:tail)
      end

      # @return [Array<Edge>]
      def reachable_edges(task)
        found = {}
        path = LinkedList.null
        collect_reachable_edges(task, found, path)
        found.values
      end

      private

      def collect_reachable_edges(task, found, path)
        next_path = build_next_path(task.name, path)

        successor_edges(task).each do |edge|
          found[edge.object_id] = edge
          collect_reachable_edges(edge.tail, found, next_path)
        end
      end

      def build_next_path(name, path)
        if path.include?(name)
          chain = path.take_while { |o| o != name }.join(' -> ')
          raise "circular dependency detected: #{chain}"
        end
        path.conj(name)
      end
    end
  end
end

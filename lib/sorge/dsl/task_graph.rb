module Sorge
  class DSL
    class TaskGraph
      Edge = Struct.new(:head, :tail)

      def initialize(dsl)
        @dsl = dsl
        @matrix = Hash.new { |hash, key| hash[key] = {} }
      end

      def add(task)
        task.predecessors.each do |_, up_task|
          @matrix[up_task.name][task.name] = Edge[up_task, task]
        end
      end

      def successor_edges(task)
        @matrix[task.name].map { |_, edge| edge }
      end

      def successors(task)
        successor_edges(task).map(&:tail)
      end

      def all_successors(task)
        reachable_edges(task).map(&:tail).uniq
      end

      # @return [Array<Edge>]
      def reachable_edges(task)
        Enumerator.new do |y|
          visit_reachable_edges(task) { |edge| y << edge }
        end
      end

      def visit_reachable_edges(task, &block)
        collect_reachable_edges(task, {}, LinkedList.null, &block)
      end

      private

      # Iterates on all reachable edges of the given task.
      # It stops recursion if block returns false.
      def collect_reachable_edges(task, found, path, &block)
        next_path = build_next_path(task.name, path)

        successor_edges(task).each do |edge|
          next if found.include?(edge.object_id)
          found[edge.object_id] = edge
          next unless yield edge
          collect_reachable_edges(edge.tail, found, next_path, &block)
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

module Sorge
  class DSL
    class TaskManager
      Edge = Struct.new(:head, :tail, :args)

      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
        @edges = Hash.new { |hash, key| hash[key] = {} }
      end

      # @return [Hash<head, Hash<tail, Edge>>] edges index
      attr_reader :edges

      def define(name, klass, &block)
        name = name.to_s
        @tasks[name] ||= klass.create(name, @dsl)
        @tasks[name].enhance(&block)
        build_edge_index(@tasks[name])
      end

      def build_edge_index(task)
        return unless task < Task

        task.all_upstreams.each do |upstream, args|
          @edges[upstream.name][task.name] = Edge.new(upstream, task, args)
        end
      end

      def [](name, scope = Scope.null)
        name = name.to_s
        if scope.root? && !@tasks.include?(name)
          raise NameError, "uninitialized task #{name}"
        end
        @tasks[scope.join(name)] || self[name, scope.parent]
      end

      # @return [Array<Edge>]
      def reachable_edges(*names)
        found = {}
        path = LinkedList.null
        names.each { |name| collect_reachable_edges(name, found, path) }
        found.values
      end

      def collect_reachable_edges(head, found, path)
        next_path = build_next_path(head, path)

        @edges[head].each do |tail, edge|
          found[edge.object_id] = edge
          collect_reachable_edges(tail, found, next_path)
        end
      end
      private :collect_reachable_edges

      def build_next_path(name, path)
        if path.include?(name)
          chain = path.take_while { |o| o != name }.join(' -> ')
          raise "circular dependency detected: #{chain}"
        end
        path.conj(name)
      end
      private :build_next_path
    end
  end
end

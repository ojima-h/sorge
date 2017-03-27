module Sorge
  class DSL
    class Task
      include Core
      extend Forwardable

      class << self
        def create(dsl, name)
          Class.new(self) do
            include dsl.global
            init(dsl, name)
          end
        end

        def successors
          @dsl.task_graph.successors(self)
        end

        alias predecessors upstreams
      end

      def initialize(job)
        @job = job
      end

      def_delegators :@job, :stash, :params

      def to_s
        task.name + ' ' + params.to_json
      end

      private

      #
      # Helper methods
      #
      def task
        self.class
      end

      def logger
        Sorge.logger
      end
    end
  end
end

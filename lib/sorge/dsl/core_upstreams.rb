module Sorge
  class DSL
    module CoreUpstreams
      include Core

      class_methods do
        def init(dsl, name)
          super
          @upstreams = {}
          @upstream_aliases = {}
        end

        # Declare upstreams.
        #
        #   task :foo do
        #     upstream :bar
        #     upstream :baz, as: :x
        #
        #     find_upstream(:bar) #=> task :bar
        #     find_upstream(:x)   #=> task :baz
        #
        #     action do
        #       up(:bar) #=> task instance of :bar
        #       up(:x)   #=> task instance of :baz
        #     end
        #   end
        def upstream(name, as: nil)
          up_task = Sorge.tasks[name, Scope.current]
          @upstreams[up_task.name] = up_task
          @upstream_aliases[name] = up_task
          @upstream_aliases[as] = up_task if as
          up_task
        end

        def upstreams
          return {} unless initialized?
          super_mixin.upstreams.merge(@upstreams)
        end

        def find_upstream(name)
          raise NameError, "undefined upstream: ##{name}" unless initialized?

          @upstream_aliases[name] \
          || @upstreams[name] \
          || super_mixin.find_upstream(name)
        end

        def successors
          @dsl.task_graph.successors(self)
        end

        alias_method :predecessors, :upstreams

        def reachable_edges
          @dsl.task_graph.reachable_edges(self)
        end

        def visit_reachable_edges(&block)
          @dsl.task_graph.visit_reachable_edges(self, &block)
        end
      end

      def upstreams
        @upstreams ||= task.upstreams.map do |name, up_task|
          [name, context.jobflow.jobs[up_task.name].task_instance]
        end.to_h
      end

      def up(name)
        upstreams[name] || upstreams[task.find_upstream(name).name]
      end
    end
  end
end

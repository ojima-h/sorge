module Sorge
  class DSL
    module CoreUpstreams
      extend Concern

      class_methods do
        def init_upstreams
          @upstreams = {}
        end

        def upstreams
          return {} unless initialized?
          super_mixin.upstreams.merge(@upstreams)
        end

        # Declare upstreams.
        #
        #   task :foo do
        #     upstream :bar
        #   end
        def upstream(name, *args)
          @upstreams[@dsl.task_manager[name, Scope.current]] = args
        end
      end
    end
  end
end

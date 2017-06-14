module Sorge
  class DSL
    module CoreUpstreams
      include Core

      class_methods do
        def init(app, name)
          super
          @_upstreams = {}
          @_upstream_aliases = {}
        end
        attr_reader :_upstreams, :_upstream_aliases

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
          up_task = app.tasks[name, scope]
          @_upstreams[up_task.name] = up_task
          @_upstream_aliases[name] = up_task
          @_upstream_aliases[as] = up_task if as
          up_task
        end

        def upstreams
          ret = {}
          super_mixins.reverse_each { |m| ret.update(m._upstreams) }
          ret
        end

        def find_upstream(name)
          o = super_mixins.find do |m|
            m._upstream_aliases[name] || m._upstreams[name]
          end

          raise NameError, "undefined upstream: ##{name}" unless o

          o._upstream_aliases[name] || o._upstreams[name]
        end
      end
    end
  end
end

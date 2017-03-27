module Sorge
  class DSL
    module CoreParams
      include Core

      class_methods do
        def init(dsl, name)
          super
          @params = {}
        end

        def params
          return {} unless initialized?
          super_mixin.params.merge(@params)
        end

        def store(name)
          @params[name.to_sym] = true
        end

        # Define params.
        #
        #     task :foo do
        #       setup { params[:time] = Time.now }
        #     end
        #
        #     task :bar do
        #       upstream :foo
        #
        #       param :time
        #     end
        #
        def param(name, value = nil, &block)
          set(name, value || block || -> { find_param(name) })
          store(name)
        end
      end

      def find_param(name)
        found = [self, *upstreams.values].find { |t| t.params.include? name }
        found.params[name] if found
      end

      def assign_params
        task.params.each do |name, _|
          params[name] = send(name)
        end
      end
    end
  end
end

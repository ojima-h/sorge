module Sorge
  class DSL
    # Common methods for Task and Mixin
    module Core
      extend Concern

      class << self
        def create(dsl, name)
          Module.new do
            include Core
            init(dsl, name)
          end
        end
      end

      include CoreAction
      include CoreSettings
      include CoreInclude
      include CoreUpstreams

      class_methods do
        def init(dsl, name)
          @dsl = dsl
          @name = name

          init_actions
          init_upstreams

          @initialized = true
        end
        attr_reader :name

        def initialized?
          defined?(@initialized) && @initialized
        end

        def inspect
          format('#<Task:0x00%x name=%s>', object_id << 1, name)
        end

        # Return a list of Mixin objects included.
        def super_mixin
          ancestors[1..-1].find { |o| o <= Core }
        end
      end
    end
  end
end

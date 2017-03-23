module Sorge
  class DSL
    # `mixin` definition is evaluated in Mixin module context.
    #
    #     mixin :foo do
    #       # this is evaluated in Mixin module context
    #     end
    #
    module Mixin
      extend Concern

      class_methods do
        include Core

        def inspect
          "#<Sorge::DSL::Mixin #{name}>"
        end
      end

      class << self
        # Create new Mixin object.
        # @param task [Rake::Task] owner task
        def create(name, dsl)
          create_base(name, dsl) do
            include dsl.global_mixin
          end
        end

        # Create new global mixin.
        # `global_mixin` does not include Application#global_mixin.
        def create_global_mixin(dsl)
          create_base(:global_mixin, dsl)
        end

        def create_base(name, dsl, &block)
          Module.new do
            include Mixin

            init(dsl, name, Mixin)

            module_eval(&block) if block_given?
          end
        end
      end
    end
  end
end

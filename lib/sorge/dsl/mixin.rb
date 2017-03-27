module Sorge
  class DSL
    # `mixin` definition is evaluated in Mixin module context.
    #
    #     mixin :foo do
    #       # this is evaluated in Mixin module context
    #     end
    #
    module Mixin
      include Base

      class << self
        # Create new Mixin object.
        # @param task [Rake::Task] owner task
        def create(dsl, name)
          Module.new do
            include Mixin
            include dsl.global
            init(dsl, name)
          end
        end
      end
    end
  end
end

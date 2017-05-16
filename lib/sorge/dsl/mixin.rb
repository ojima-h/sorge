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

      class_methods do
        # Create new Mixin object.
        # @param task [Rake::Task] owner task
        def create(app, name)
          Module.new do
            include Mixin
            init(app, name)
            use 'global' unless name == 'global'
          end
        end
      end
    end
  end
end

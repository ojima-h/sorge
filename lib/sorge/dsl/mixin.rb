module Sorge
  class DSL
    # `mixin` definition is evaluated in Mixin module context.
    #
    #     mixin :foo do
    #       # this is evaluated in Mixin module context
    #     end
    #
    module Mixin
      # Create new Mixin object.
      # @param task [Rake::Task] owner task
      def self.create(name, dsl)
        Module.new do
          include Mixin
          extend Mixin::ClassMethods
          init(name, dsl)

          include dsl.global_mixin
          extend helpers
        end
      end

      # Create new global mixin.
      # `global_mixin` does not include Application#global_mixin.
      def self.create_global_mixin(dsl)
        Module.new do
          include Mixin
          extend Mixin::ClassMethods
          init(:global_mixin, dsl)

          extend helpers
        end
      end

      module ClassMethods
        include Core

        def included(obj)
          return unless obj.is_a? Core
          merge_helpers(obj)
        end

        def merge_helpers(obj)
          my_helpers = helpers
          obj.helpers.module_eval { include my_helpers }
          obj.extend(obj.helpers) # re-extend by helpers
        end

        def inspect
          "#<Sorge::DSL::Mixin #{name}>"
        end
      end
    end
  end
end

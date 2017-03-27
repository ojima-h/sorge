module Sorge
  class DSL
    module CoreInclude
      extend Concern

      class_methods do
        private

        # Include mixins.
        #
        # All methods, actions and settings are inherited.
        #
        #     mixin :foo do
        #       param :country
        #     end
        #
        #     play :bar do
        #       include :bar
        #       params_spec #=> { country: {} }
        #     end
        #
        # When Module objects are given, it includes them as usual.
        #
        # @param mod [Array<Symbol, String, Module>] mixin name or module.
        def include(*mod)
          ms = mod.map { |m| resolve_mixin(m) }
          super(*ms)
        end

        def resolve_mixin(mod)
          return mod if mod.is_a? Module

          mixin = @dsl.task_manager[mod, Scope.current]
          raise "#{mod} is not a mixin" unless mixin < Mixin

          mixin
        end
      end
    end
  end
end

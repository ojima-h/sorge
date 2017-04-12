module Sorge
  class DSL
    module CoreInclude
      include Core

      class_methods do
        private

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

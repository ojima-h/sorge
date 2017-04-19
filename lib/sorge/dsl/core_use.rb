module Sorge
  class DSL
    module CoreUse
      include Core

      class_methods do
        private

        def use(*mixins)
          ms = mixins.map do |name|
            task = @dsl.task_manager[name, Scope.current]
            raise "#{mod} is not a mixin" unless task < Mixin
            task
          end

          include(*ms)
        end
      end
    end
  end
end

module Sorge
  class DSL
    module CoreUse
      include Core

      class_methods do
        private

        def use(*mixins)
          ms = mixins.map do |name|
            task = app.tasks[name, scope]
            raise "#{task} is not a mixin" unless task < Mixin
            task
          end

          include(*ms)
        end
      end
    end
  end
end

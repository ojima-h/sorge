module Sorge
  class DSL
    module CoreTime
      include Core

      class_methods do
        def init(dsl, name)
          super
          @trigger = Trigger.default
          @time_trunc = TimeTrunc.default
        end

        def time_trunc(type = nil, *args, &block)
          return @time_trunc if type.nil? && !block_given?

          @time_trunc = TimeTrunc.build(type, *args, &block)
        end

        def trigger(type = nil, *args, &block)
          return @trigger if type.nil? && !block_given?

          @trigger = Trigger.build(type, *args, &block)
        end
      end
    end
  end
end

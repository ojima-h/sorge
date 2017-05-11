module Sorge
  class DSL
    module CoreTime
      include Core

      class_methods do
        def init(dsl, name)
          super
          @trigger = nil
          @time_trunc = nil
        end

        def time_trunc(type = nil, *args, &block)
          if type || block_given?
            @time_trunc = TimeTrunc.build(type, *args, &block)
          elsif !initialized?
            TimeTrunc.default
          else
            @time_trunc || super_mixin.time_trunc
          end
        end

        def trigger(type = nil, *args, &block)
          if type || block_given?
            @trigger = Trigger.build(type, *args, &block)
          elsif !initialized?
            Trigger.default
          else
            @trigger || super_mixin.trigger
          end
        end
      end
    end
  end
end

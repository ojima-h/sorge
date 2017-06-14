module Sorge
  class DSL
    module CoreTime
      include Core

      class_methods do
        def init(app, name)
          super
          @_trigger = nil
          @_time_trunc = nil
        end
        attr_reader :_trigger, :_time_trunc

        def time_trunc(type = nil, *args, &block)
          if type || block_given?
            @_time_trunc = TimeTrunc.build(type, *args, &block)
          else
            o = super_mixins.find(&:_time_trunc)
            o ? o._time_trunc : TimeTrunc.default
          end
        end

        def trigger(type = nil, *args, &block)
          if type || block_given?
            @_trigger = Trigger.build(self, type, *args, &block)
          else
            o = super_mixins.find(&:_trigger)
            o ? o._trigger : Trigger.default
          end
        end
      end
    end
  end
end

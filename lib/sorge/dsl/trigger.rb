module Sorge
  class DSL
    module Trigger
      class << self
        def classes
          @classes ||= {}
        end

        def register(name, klass)
          classes[name] = klass
        end

        def [](type)
          classes.fetch(type) do
            raise NameError, "undefined trigger #{type}"
          end
        end

        def default
          @default ||= self[:default].new
        end

        def build(type, *args, &block)
          if type.is_a?(Symbol)
            self[type].new(*args, &block)
          else
            type || block
          end
        end
      end

      class Base
        def self.register(name)
          Trigger.register(name, self)
        end

        def call(_pending)
          raise NotImplementedError
        end
      end

      class Default < Base
        register :default

        def call(pending)
          [pending, []] # trigger all
        end
      end

      class Periodic < Base
        register :periodic

        def initialize(period)
          @period = period
          @last_triggered = Time.now.to_i
        end

        def call(pending)
          now = Time.now.to_i

          return [[], pending] if now - @last_triggered < @period

          @last_triggered = now
          [pending, []]
        end
      end

      class Lag < Base
        register :lag

        def initialize(lag)
          @lag = lag
          @max_time = 0
        end

        def call(pending)
          @max_time = [@max_time, *pending].max
          ready, rest = pending.partition do |time|
            @max_time - time >= @lag
          end
          [ready, rest]
        end
      end

      class Delay < Base
        register :delay

        def initialize(delay)
          @delay = delay
        end

        def call(pending)
          now = Time.now.to_i
          ready, rest = pending.partition do |time|
            now - time >= @delay
          end
          [ready, rest]
        end
      end
    end
  end
end

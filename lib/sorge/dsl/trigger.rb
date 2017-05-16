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
          @default ||= self[:default].new(nil)
        end

        def build(task, type, *args, &block)
          if type.is_a?(Symbol)
            self[type].new(task, *args, &block)
          else
            self[:custom].new(task, type || block, *args)
          end
        end
      end

      class Base
        class << self
          attr_accessor :type

          def register(name)
            Trigger.register(name, self)
            self.type = name
          end
        end

        def initialize(task)
          @task = task
        end

        def call(_panes, _context)
          raise NotImplementedError
        end
      end

      class Default < Base
        register :default

        def call(panes, _context)
          [panes, []] # trigger all
        end
      end

      class Custom < Base
        register :custom

        def initialize(_task, trigger)
          @trigger = trigger
        end

        def call(panes, context)
          @trigger.call(panes, context)
        end
      end

      class Periodic < Base
        register :periodic

        def initialize(_task, period)
          @period = period
        end

        def call(panes, context)
          s = context.state
          now = Time.now
          s[:last] ||= now

          return [[], panes] if now - s[:last] < @period

          s[:last] = now
          [panes, []]
        end
      end

      class Lag < Base
        register :lag

        def initialize(_task, lag)
          @lag = lag
        end

        def call(panes, context)
          s = context.state
          s[:latest] = [s[:latest] || Time.at(0), *panes.map(&:time)].max

          panes.partition do |pane|
            s[:latest] - pane.time >= @lag
          end
        end
      end

      class Delay < Base
        register :delay

        def initialize(_task, delay)
          @delay = delay
        end

        def call(panes, _context)
          now = Time.now
          panes.partition do |pane|
            now - pane.time >= @delay
          end
        end
      end

      class Align < Base
        register :align

        def initialize(task, lag = 0)
          @task = task
          @lag = lag
        end

        def call(panes, context)
          min_time = @task.upstreams.map do |task_name, _|
            next 0 unless context.jobflow_status.include?(task_name)
            context.jobflow_status[task_name].position
          end.min

          panes.partition do |pane|
            pane.time <= min_time - @lag
          end
        end
      end
    end
  end
end

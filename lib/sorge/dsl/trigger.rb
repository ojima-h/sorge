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

        def call(_panes, _jobflow_status)
          raise NotImplementedError
        end

        def state
          {}
        end

        def state=(state); end

        def dump_state
          state.merge(type: self.class.type)
        end

        def restore_state(state)
          self.state = state if state[:type] == self.class.type
        end
      end

      class Default < Base
        register :default

        def call(panes, _jobflow_status)
          [panes, []] # trigger all
        end
      end

      class Custom < Base
        register :custom

        def initialize(_task, trigger)
          @trigger = trigger
        end

        def call(panes, jobflow_status)
          @trigger.call(panes, jobflow_status)
        end
      end

      class Periodic < Base
        register :periodic

        def initialize(_task, period)
          @period = period
          @last = Time.now.to_i
        end

        def state
          { last: @last }
        end

        def state=(state)
          @last = state[:last]
        end

        def call(panes, _jobflow_status)
          now = Time.now.to_i

          return [[], panes] if now - @last < @period

          @last = now
          [panes, []]
        end
      end

      class Lag < Base
        register :lag

        def initialize(_task, lag)
          @lag = lag
          @latest = 0
        end

        def state
          { latest: @latest }
        end

        def state=(state)
          @latest = state[:latest]
        end

        def call(panes, _jobflow_status)
          @latest = [@latest, *panes.map(&:time)].max

          panes.partition do |pane|
            @latest - pane.time >= @lag
          end
        end
      end

      class Delay < Base
        register :delay

        def initialize(_task, delay)
          @delay = delay
        end

        def call(panes, _jobflow_status)
          now = Time.now.to_i
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

        def call(panes, jobflow_status)
          min_time = @task.upstreams.map do |task_name, _|
            next 0 unless jobflow_status.include?(task_name)
            jobflow_status[task_name].position
          end.min

          panes.partition do |pane|
            pane.time <= min_time - @lag
          end
        end
      end
    end
  end
end

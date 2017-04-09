module Sorge
  class DSL
    module Window
      class << self
        def classes
          @classes ||= {}
        end

        def register(name, klass)
          classes[name] = klass
        end

        def [](type)
          classes.fetch(type) do
            raise NameError, "undefined window type #{type}"
          end
        end
      end

      class Base
        def self.register(name)
          Window.register(name, self)
        end

        def initialize(task, delay: 0, **options, &block)
          @task = task
          @options = options
          @block = block

          @delay = delay
        end

        def update(state, name, time)
          init_state(state)
          tm = truncate(time)
          enqueue(state, tm)
          tm = update_upstream(state, name, tm)
          tm = apply_delay(tm)
          wm = update_watermark(state, tm)
          emit(state, wm)
        end

        private

        def init_state(state)
          state[:up] ||= @task.upstreams.keys.map { |k| [k, 0] }.to_h
          state[:q] ||= []
          state[:wm] ||= 0
        end

        def truncate(time)
          time
        end

        def enqueue(state, time)
          state[:q] << time unless state[:q].include?(time)
        end

        def update_upstream(state, name, time)
          unless state[:up].include?(name)
            raise Error, "#{name} is not an upstream of #{@task.name}"
          end

          state[:up][name] = [state[:up][name], time].max
          state[:up].values.min
        end

        def apply_delay(time)
          time - @delay
        end

        def update_watermark(state, time)
          state[:wm] = [state[:wm], time].max
        end

        def emit(state, watermark)
          ready, remain = state[:q].partition { |time| time <= watermark }
          state[:q] = remain
          ready.sort
        end
      end

      class Null < Base
        register :null
      end

      class Custom < Base
        register :custom

        def update(state, name, time)
          @block.call(state, name, time)
        end
      end

      class Tumbling < Base
        register :tumbling

        def initialize(task, size:, delay: 1, **options, &block)
          super
          @size = size
        end

        def truncate(time)
          return time if @size <= 1
          time / @size * @size
        end
      end

      class Daily < Base
        register :daily

        def initialize(task, wday: 0, **options, &block)
          super
        end

        def truncate(time)
          Time.at(time).to_date.to_time.to_i
        end
      end

      class Weekly < Base
        register :weekly

        def initialize(task, wday: 0, **options, &block)
          super
          @wday = wday
        end

        def truncate(time)
          dt = Time.at(time).to_date
          delta = dt.wday - @wday
          (dt - (delta < 0 ? 7 : 0)) - delta
        end
      end

      class Monthly < Base
        register :monthly

        def initialize(task, mday: 1, **options, &block)
          super
          @mday = mday
        end

        def truncate(time)
          dt = Time.at(time).to_date
          delta = dt.mday - @mday
          dt.prev_month(delta < 0 ? 1 : 0) - delta
        end
      end
    end
  end
end

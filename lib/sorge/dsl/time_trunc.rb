module Sorge
  class DSL
    module TimeTrunc
      class << self
        def classes
          @classes ||= {}
        end

        def register(name, klass)
          classes[name] = klass
        end

        def [](type)
          classes.fetch(type) do
            raise NameError, "undefined time_trunc type #{type}"
          end
        end

        def default
          @default ||= self[:default].new
        end

        def build(type, *args, &block)
          if type.is_a?(Symbol)
            self[type].new(*args, &block)
          elsif type.is_a?(Integer)
            self[:default].new(type)
          else
            type || block
          end
        end
      end

      class Base
        def self.register(name)
          TimeTrunc.register(name, self)
        end

        def call(_time)
          raise NotImplementedError
        end
      end

      class Default < Base
        register :default

        def initialize(sec = 0)
          @sec = sec
        end

        def call(time)
          return time if @sec.zero?
          Time.at(time.to_i / @sec * @sec)
        end
      end

      class Hour < Base
        register :hour

        def call(time)
          Time.at(time.to_i / 3600 * 3600)
        end
      end

      class Day < Base
        register :day

        def call(time)
          time.to_date.to_time
        end
      end

      class Week < Base
        register :week

        def initialize(wday = 0)
          @wday = wday
        end

        def call(time)
          dt = time.to_date
          delta = dt.wday - @wday
          ((dt - (delta < 0 ? 7 : 0)) - delta).to_time
        end
      end

      class Month < Base
        register :month

        def initialize(mday = 1)
          @mday = mday
        end

        def call(time)
          dt = time.to_date
          delta = dt.mday - @mday
          (dt.prev_month(delta < 0 ? 1 : 0) - delta).to_time
        end
      end
    end
  end
end

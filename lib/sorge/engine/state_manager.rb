module Sorge
  class Engine
    class StateManager
      def initialize(engine)
        @engine = engine
        @data = {}
        @mtx = Mutex.new
      end
      attr_reader :data

      def fetch(name)
        return {} unless @data.include?(name)
        Marshal.load(@data[name])
      end

      def update(name, hash)
        @data[name] = Marshal.dump(hash)
      end

      def synchronize(&block)
        @mtx.synchronize(&block)
      end
    end
  end
end

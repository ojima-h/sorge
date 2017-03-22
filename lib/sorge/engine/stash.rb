module Sorge
  class Engine
    # Stash stores tasks states.
    class Stash
      def initialize(engine)
        @engine = engine
        @data = Hash.new { |hash, key| hash[key] = {} }
        @cache = {}
      end
      attr_reader :data

      def [](name)
        @data[name]
      end

      def update(name)
        @cache[name] = Marshal.dump(@data[name])
      end
    end
  end
end

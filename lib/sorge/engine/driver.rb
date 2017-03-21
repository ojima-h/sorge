module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
      end

      def invoke(task, params)
        batch = Batch.new(@engine)
        batch.start(task, params)
        batch
      end
    end
  end
end

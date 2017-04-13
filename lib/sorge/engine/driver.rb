module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @error = nil
      end
      attr_reader :engine

      def submit(task_name, time)
        @engine.event_queue.submit(:run, name: task_name, time: time)
      end

      # Run task synchronously
      def run(task_name, time)
        submit(task_name, time)
        shutdown
      end

      def shutdown
        @engine.savepoint.stop
        @engine.event_queue.shutdown
        raise @error if @error
      end

      def kill(error)
        @error = error
        @engine.event_queue.kill
      end
    end
  end
end

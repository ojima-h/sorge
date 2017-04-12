module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @finish_event = Concurrent::Event.new
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
        @finish_event.wait
        raise @error if @error
      end

      def check_finished
        return unless @engine.event_queue.empty? && @engine.task_runner.empty?
        @finish_event.set
      end

      def kill(error)
        @error = error
        @finish_event.set
      end
    end
  end
end

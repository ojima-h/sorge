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

      def resume(file_path)
        hash = @engine.savepoint.read(file_path)
        @engine.task_states.replace(hash[:states])
        @engine.event_queue.resume(hash[:queue], hash[:running])
      end
    end
  end
end

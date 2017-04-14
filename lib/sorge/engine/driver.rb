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
        self
      end

      def shutdown
        @engine.savepoint.stop
        @engine.event_queue.shutdown
        raise @error if @error
        self
      end

      def kill(error)
        @error = error
        @engine.event_queue.kill
        self
      end

      def resume(file_path = nil)
        file_path ||= File.read(@engine.savepoint.latest_file_path)

        hash = @engine.savepoint.read(file_path)
        hash[:states].each { |k, v| @engine.task_states[k] = v }
        @engine.event_queue.resume(hash[:queue], hash[:running])
        self
      end
    end
  end
end

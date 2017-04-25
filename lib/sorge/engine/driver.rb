module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @error = nil
      end
      attr_reader :engine

      def submit(name, time)
        DSL.instance.task_manager.validate_name(name)
        @engine.event_queue.submit(:run, name: name, time: time)
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

      def resume(file_path = 'latest')
        hash = @engine.savepoint.read(file_path)
        hash[:states].each { |k, v| @engine.task_states[k] = v }

        if @engine.application.remote_mode?
          @engine.event_queue.resume(hash[:queue], hash[:running])
        end
        self
      end
    end
  end
end

module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
      end
      attr_reader :engine

      def submit(task_name, time)
        @engine.app.tasks.validate_name(task_name)
        @engine.jobflow_operator.submit(task_name, time)
      end

      def shutdown
        @engine.jobflow_operator.shutdown
      end

      def kill
        @engine.jobflow_operator.kill
      end

      def resume(file_path = 'latest')
        data = @engine.savepoint.read(file_path)
        @engine.jobflow_operator.resume(data)
      end
    end
  end
end

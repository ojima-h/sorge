module Sorge
  class Engine
    class Worker
      def initialize(engine)
        @engine = engine
        @task_worker = Concurrent::FixedThreadPool.new(4)
      end
      attr_reader :task_worker

      def error_handler(error)
        Sorge.logger.fatal(Util.format_error_info(error))
        @engine.application.kill
      end

      def with_error_handler
        yield
      rescue Exception => exception
        error_handler(exception)
        raise
      end

      def post(&block)
        @task_worker.post(block) do |my_block|
          with_error_handler(&my_block)
        end
      end
    end
  end
end

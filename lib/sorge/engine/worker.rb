module Sorge
  class Engine
    class Worker
      def initialize(engine)
        @engine = engine
        @job_worker = Concurrent::CachedThreadPool.new
      end
      attr_reader :job_worker
      alias task_worker job_worker

      def capture_exception
        yield
      rescue Exception => exception
        Sorge.logger.fatal(Util.format_error_info(exception))
        @engine.application.kill(exception)
      end

      def kill
        @job_worker.kill
      end
    end
  end
end

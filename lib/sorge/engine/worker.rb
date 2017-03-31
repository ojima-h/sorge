module Sorge
  class Engine
    class Worker
      def initialize(engine)
        @engine = engine
        @job_worker = Concurrent::CachedThreadPool.new
      end
      attr_reader :job_worker

      def capture_exception(raise_error = false)
        yield
      rescue Exception => exception
        Sorge.logger.error("fatal:\n" + Util.format_error_info(exception))
        @engine.kill
        raise if raise_error
      end

      def kill
        @job_worker.kill
      end
    end
  end
end

module Sorge
  class Engine
    class Worker
      def initialize(engine)
        @engine = engine
        @job_worker = Concurrent::CachedThreadPool.new
      end

      def post_job(*args, &block)
        @job_worker.post(*args) do
          capture_exception(&block)
        end
      end

      def capture_exception
        yield
      rescue => error
        Sorge.logger.error("error:\n" + Util.format_error_info(error))
      rescue Exception => exception
        Sorge.logger.error("error:\n" + Util.format_error_info(exception))
        # TODO: kill application
      end
    end
  end
end

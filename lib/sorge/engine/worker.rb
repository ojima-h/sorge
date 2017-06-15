module Sorge
  class Engine
    class Worker
      JOBFLOW = Object.new

      def initialize(engine)
        @engine = engine
        @workers = {
          JOBFLOW => Concurrent::FixedThreadPool.new(1),
          :default => Concurrent::FixedThreadPool.new(4)
        }
      end

      def define(name, thread_num)
        @workers[name] = \
          if thread_num <= 0
            Concurrent::CachedThreadPool.new
          else
            Concurrent::ThreadPoolExecutor.new(max_threads: thread_num)
          end
      end

      def validate_name!(name)
        raise KeyError, "worker '#{name}' is not defined" \
          unless @workers.include?(name)
      end

      def error_handler(error)
        Sorge.logger.fatal(Util.format_error_info(error))
        Thread.new { @engine.app.kill(error) }
      end

      def with_error_handler
        yield
      rescue Exception => exception
        error_handler(exception)
        raise
      end

      def post(name, &block)
        @workers.fetch(name).post(block) do |my_block|
          with_error_handler(&my_block)
        end
      end

      def kill
        @workers[JOBFLOW].kill # kill jobflow worker first
        @workers.each_value(&:kill)
      end
    end
  end
end

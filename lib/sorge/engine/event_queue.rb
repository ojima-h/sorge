module Sorge
  class Engine
    class EventQueue
      def initialize(engine)
        @engine = engine
        @queue = []
        @mutex = Mutex.new

        @agent = Concurrent::Agent.new(nil)
        @handler_prefix = 'handle_'
      end

      def submit(method, params)
        @mutex.synchronize { @queue << [method, params] }
        async(&method(:dispatch))
      end

      def handle_notify(name:, time:, dest:)
        TaskHandler.new(@engine, dest).notify(name, time)
      end

      private

      #
      # Asynchronous Execution
      #
      def dispatch
        method, params = @mutex.synchronize { @queue.shift }
        send(:"#{handler_prefix}#{method}", params)
      end

      def async(*args, &block)
        worker = @engine.worker.task_worker
        @agent.send_via!(worker, args, block) do |_, my_args, my_block|
          capture_exception { my_block.call(*my_args) }
          nil
        end
      end

      def capture_exception
        yield
      rescue Exception => exception
        Sorge.logger.error("fatal:\n" + Util.format_error_info(exception))
      end
    end
  end
end

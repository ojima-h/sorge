module Sorge
  class Engine
    class EventQueue
      def initialize(engine)
        @engine = engine
        @queue = []

        @agent = Concurrent::Agent.new(nil)
        @handler_prefix = 'handle_'
      end
      attr_reader :queue

      def empty?
        @queue.empty?
      end

      def submit(method, params)
        Engine.synchronize { @queue << [method, params] }
        async(&method(:dispatch))
      end

      def peek(method, params)
        Engine.synchronize { @queue.unshift([method, params]) }
        async(&method(:dispatch))
      end

      #
      # Handlers
      #
      def handle_notify(name:, time:, dest:)
        TaskHandler.new(@engine, dest).notify(name, time)
      end

      def handle_run(name:, time:)
        TaskHandler.new(@engine, name).run(time)
      end

      def handle_complete(name:, time:, state:)
        TaskHandler.new(@engine, name).complete(time, state)
        @engine.driver.task_finished
      end

      def handle_savepoint
        @engine.savepoint.dump
      end

      private

      #
      # Asynchronous Execution
      #
      def dispatch
        method, params = Engine.synchronize { @queue.shift }
        send(:"#{@handler_prefix}#{method}", params)
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

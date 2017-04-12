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

      #
      # Handlers
      #
      def handle_notify(name:, time:, dest:)
        TaskHandler.new(@engine, dest).notify(name, time)
      end

      def handle_run(name:, time:)
        TaskHandler.new(@engine, name).run(time)
      end

      def handle_successed(name:, time:, state:)
        TaskHandler.new(@engine, name).successed(time, state)
      end

      def handle_failed(name:, time:, state:)
        TaskHandler.new(@engine, name).failed(time, state)
      end

      def handle_savepoint
        @engine.savepoint.update
      end

      private

      #
      # Asynchronous Execution
      #
      def dispatch
        method, params = Engine.synchronize { @queue.shift }
        send(:"#{@handler_prefix}#{method}", params)
        @engine.driver.check_finished
        @engine.savepoint.fine_update
      end

      def async(*args, &block)
        worker = @engine.worker.task_worker
        @agent.send_via!(worker, args, block) do |_, my_args, my_block|
          @engine.worker.capture_exception do
            my_block.call(*my_args)
          end
          nil
        end
      end
    end
  end
end

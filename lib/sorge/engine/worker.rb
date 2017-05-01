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
        @engine.application.kill(error)
      end

      def with_error_handler
        yield
      rescue Exception => exception
        error_handler(exception)
        raise
      end

      def new_agent
        Concurrent::Agent.new(nil, error_handler: method(:error_handler))
      end

      def post_agent(agent, *args)
        agent.send_via(task_worker, *args) do |_, *my_args|
          with_error_handler { yield(*my_args) }
          nil
        end
      end
    end
  end
end

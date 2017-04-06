module Sorge
  class Engine
    class Agent
      extend Forwardable

      def initialize(engine, task)
        @engine = engine
        @task = task
        @state = TaskState.new(engine, task.name)
        @agent = Concurrent::Agent.new(nil)
      end
      attr_reader :state
      def_delegators :@task, :name

      # TODO: DELETE
      JobMock = Struct.new(:stash, :params)
      def job
        JobMock[{}, {}]
      end

      def execute
        @task.new(self).execute
      end

      def submit(method, params)
        state.update { |s| s.queue << [method, params] }
        async(&method(:dispatch))
      end

      def proc_upstream(name:, time:)
      end

      def update_watermark(hash, time)
        current_time = hash[:time]
        if current_time.nil? || current_time < time
          hash[:time] = time
          current_time
        elsif time < current_time
          time
        end
      end

      private

      def dispatch
        state.init
        method, params = state.queue.first.dup

        send(:"proc_#{method}", params)

        state.queue.shift
        state.save
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
      rescue => error
        Sorge.logger.error("error:\n" + Util.format_error_info(error))
      rescue Exception => exception
        Sorge.logger.error("error:\n" + Util.format_error_info(exception))
      end
    end
  end
end

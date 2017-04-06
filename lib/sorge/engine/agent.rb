module Sorge
  class Engine
    class Agent
      extend Forwardable

      Context = Struct.new(:_time, :job) do
        def time
          Time.at(_time)
        end
      end

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

      def execute(time)
        @task.new(Context[time, job]).execute
      end

      def submit(method, params)
        state.session { state.queue << [method, params] }
        async(&method(:dispatch))
      end

      def proc_upstream(name:, time:)
        update_watermark(name, time)

        tm = update_watermark('__self__', min_watermark)
        return if tm.nil?

        submit :run, time: tm
      end

      def proc_run(time)
        execute(time)
      end

      private

      def update_watermark(name, time)
        return if time.nil?

        current_time = state.watermarks[name]
        if current_time.nil? || current_time < time
          state.watermarks[name] = time
          current_time
        elsif time < current_time
          time
        end
      end

      def min_watermark
        state.watermarks.reject { |k| k == '__self__' }.values.min
      end

      #
      # Asynchronous Execution
      #
      def dispatch
        state.session do
          method, params = state.queue.shift
          send(:"proc_#{method}", params)
        end
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

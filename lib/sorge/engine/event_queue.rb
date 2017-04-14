module Sorge
  class Engine
    class EventQueue
      def initialize(engine)
        @engine = engine
        @queue = []

        @agent = @engine.worker.new_agent
        @handler_prefix = 'handle_'

        @stopping = Concurrent::AtomicBoolean.new
        @stop_event = Concurrent::Event.new
      end
      attr_reader :queue

      def submit(method, *args)
        @engine.synchronize { @queue << [method, *args] }
        async(&method(:dispatch))
      end

      def shutdown
        submit(:stop) if @stopping.make_true
        @stop_event.wait
      end

      def kill
        @stopping.make_true
        @stop_event.set
      end

      def resume(queue, running)
        @engine.synchronize do
          @engine.task_runner.resume(running, collect_finished(queue))
          queue.each do |method, *args|
            submit(method, *args) unless control_method?(method)
          end
        end
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

      def handle_successed(name:, time:, state:, job_id:)
        TaskHandler.new(@engine, name).successed(job_id, time, state)
      end

      def handle_failed(name:, time:, state:, job_id:)
        TaskHandler.new(@engine, name).failed(job_id, time, state)
      end

      def handle_savepoint
        @engine.savepoint.update
      end

      def handle_stop
        return unless @stopping.true?

        if @queue.empty? && @engine.task_runner.empty?
          @stop_event.set
        else
          sleep 0.01
          submit(:stop) # check again
        end
      end

      private

      def control_method?(name)
        %i(savepoint stop).include?(name)
      end

      #
      # Asynchronous Execution
      #
      def dispatch
        return if @stop_event.set?

        method, *args = @engine.synchronize { @queue.shift }
        send(:"#{@handler_prefix}#{method}", *args)

        @engine.savepoint.fine_update if control_method?(method)
      end

      def async(*args, &block)
        return if @stop_event.set?
        @engine.worker.post_agent(@agent, *args, &block)
      end

      def collect_finished(queue)
        ret = {}
        queue.each do |method, params|
          next unless %i(successed failed).include?(method)
          ret[params[:job_id]] = true
        end
        ret
      end
    end
  end
end

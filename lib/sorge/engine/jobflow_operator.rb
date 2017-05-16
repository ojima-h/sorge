module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine

        @task_operators = {}
        @jobflow_status = JobflowStatus.new.freeze

        @worker = AsyncWorker.new(@engine)
        @timer = nil
        @mutex = Mutex.new
        @started = Concurrent::AtomicBoolean.new
        @complete = Concurrent::Event.new
        @stop = false
        @stopped = Concurrent::Event.new
      end

      def start
        return unless @started.make_true

        setup_task_operators
        start_timer
      end

      def submit(task_name, time)
        post(task_name, time, &method(:ns_submit))
      end

      def resume(data)
        post(data, &method(:ns_resume))
      end

      def wait_complete
        @complete.wait
      end

      def stop
        @mutex.synchronize do
          @timer.shutdown if @timer
          @stop = true
          post(&method(:ns_stop))
        end
      end

      def wait_stop
        @stopped.wait
      end

      def kill
        @task_operators.each_value(&:kill)
        @stopped.set
        @complete.set
      end

      private

      def start_timer
        opts = { execution_interval: @engine.config.heartbeat_interval }

        @timer = Concurrent::TimerTask.execute(opts) do
          @engine.worker.with_error_handler do
            post(&method(:ns_update))
          end
        end
      end

      def setup_task_operators
        @engine.app.tasks.each_task do |task_name, _|
          @task_operators[task_name] = TaskOperator.new(@engine, task_name)
        end
      end

      def post(*args, &block)
        @mutex.synchronize do
          raise AlreadyStopped if @stop
          start
          @worker.post(*args, &block)
        end
      end

      #
      # Async Handlers
      #
      def ns_submit(task_name, time)
        task_operator = @task_operators.fetch(task_name)
        s = task_operator.post(time, @jobflow_status)
        @jobflow_status = @jobflow_status.merge(task_name => s).freeze
      end

      def ns_resume(data)
        @jobflow_status = JobflowStatus.restore(data)
        @task_operators.each do |task_name, task_operator|
          task_operator.resume(@jobflow_status[task_name])
        end
      end

      def ns_update
        if @engine.local? && @jobflow_status.pending?
          ns_flush_task
        else
          ns_update_tasks
        end

        ns_savepoint
        @jobflow_status.complete? ? @complete.set : @complete.reset
      end

      def ns_update_tasks
        next_jobflow_status = JobflowStatus.new
        @task_operators.each do |task_name, task_operator|
          next_jobflow_status[task_name] =
            task_operator.update(@jobflow_status)
        end
        @jobflow_status = next_jobflow_status.freeze
      end

      def ns_flush_task
        task_name, = @jobflow_status.find { |_, o| o.pending? }
        return if task_name.nil?

        s = @task_operators[task_name].flush
        @jobflow_status = @jobflow_status.merge(task_name => s).freeze
      end

      def ns_savepoint
        @engine.savepoint.save(@jobflow_status.dump)
      end

      def ns_stop
        ns_stop_tasks
        ns_savepoint
        @stopped.set
      end

      def ns_stop_tasks
        next_jobflow_status = JobflowStatus.new
        @task_operators.each_value(&:stop)
        @task_operators.each do |task_name, task_operator|
          next_jobflow_status[task_name] = task_operator.wait_stop
        end
        @jobflow_status = next_jobflow_status.freeze
      end
    end
  end
end

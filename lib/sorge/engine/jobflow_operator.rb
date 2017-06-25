module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine

        @task_operators = {}
        @status = JobflowStatus.new.freeze

        @worker = AsyncWorker.new(@engine, Worker::JOBFLOW)
        @timer = nil
        @mutex = Mutex.new
        @started = Concurrent::AtomicBoolean.new
        @complete = Concurrent::Event.new
        @stop = false
        @stopped = Concurrent::Event.new

        @flush = false
      end
      attr_reader :status

      def [](task_name)
        @task_operators[task_name]
      end

      def start
        return unless @started.make_true

        setup_task_operators
        start_timer
      end

      def submit(task_name, time)
        start
        post(task_name, time, &method(:ns_submit))
      end

      def run(task_name, time)
        @flush = true
        submit(task_name, time)
        wait_complete
      end

      def resume(data)
        start
        post(data, &method(:ns_resume))
      end

      def wait_complete
        @complete.wait
      end

      def stop
        @mutex.synchronize do
          @timer.shutdown if @timer
          @stop = true
          @worker.post(&method(:ns_stop))
        end
      end

      def wait_stop(timeout = nil)
        @stopped.wait(timeout)
      end

      def kill
        @timer.shutdown if @timer
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
          @worker.post(*args, &block)
        end
      end

      #
      # Async Handlers
      #
      def ns_submit(task_name, time)
        task_operator = @task_operators.fetch(task_name)
        s = task_operator.post(time, @status)
        @status = @status.merge(task_name => s).freeze
      end

      def ns_resume(data)
        @status = JobflowStatus.restore(data)
        @task_operators.each do |task_name, task_operator|
          task_operator.resume(@status[task_name])
        end
      end

      def ns_update
        if @flush && @status.pending?
          ns_flush_task
        else
          ns_update_tasks
        end

        ns_savepoint
        @status.complete? ? @complete.set : @complete.reset
      end

      def ns_update_tasks
        next_status = JobflowStatus.new
        @task_operators.each do |task_name, task_operator|
          next_status[task_name] = task_operator.update(@status)
        end
        @status = next_status.freeze
      end

      def ns_flush_task
        task_name, = @status.find { |_, o| o.pending? }
        return if task_name.nil?

        s = @task_operators[task_name].flush
        @status = @status.merge(task_name => s).freeze
      end

      def ns_savepoint
        @engine.savepoint.save(@status.dump)
      end

      def ns_stop
        ns_stop_tasks
        ns_savepoint
        @stopped.set
        @complete.set
      end

      def ns_stop_tasks
        next_status = JobflowStatus.new
        @task_operators.each_value(&:stop)
        @task_operators.each do |task_name, task_operator|
          next_status[task_name] = task_operator.wait_stop
        end
        @status = next_status.freeze
      end
    end
  end
end

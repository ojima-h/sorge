module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine

        @queue = TimeoutQueue.new
        @worker = Concurrent::IVar.new

        @task_operators = {}
        @jobflow_context = {}
        initialize_with_tasks

        @heartbeat_interval = 0.1
        @next_heartbeat = nil
        @stopped = Concurrent::Event.new
        @killed = Concurrent::Event.new
      end

      def submit(task_name, time)
        enqueue { post_task(task_name, time) }
      end

      def invoke(task_name, time)
        post_task(task_name, time)
        loop do
          @killed.wait(heartbeat)
          break if complete?
          break if @killed.set?
        end
      end

      def shutdown
        stop_worker
        @task_operators.each_value(&:shutdown)
      end

      def wait_for_termination
        @task_operators.each_value(&:wait_for_termination)
      end

      def kill
        @task_operators.each_value(&:kill)
        @killed.set
      end

      private

      def initialize_with_tasks
        Sorge.tasks.each do |task_name, _|
          @task_operators[task_name] = TaskOperator.new(@engine, task_name)
          @jobflow_context[task_name] = TaskStatus.new.freeze!
        end
        @jobflow_context.freeze
      end

      def post_task(task_name, time)
        task_operator = @task_operators[task_name]
        st = task_operator.post(time, @jobflow_context)
        @jobflow_context = @jobflow_context.merge(task_name => st).freeze
      end

      def update_tasks
        next_jobflow_context = {}

        @task_operators.each do |task_name, task_operator|
          next_jobflow_context[task_name] =
            task_operator.update(@jobflow_context)
        end

        @jobflow_context = next_jobflow_context.freeze
        # TODO: savepoint.update(jobflow_context)
      end

      def complete?
        @task_operators.each_value.all?(&:complete?) \
        && !@jobflow_context.each_value.any?(&:next?)
      end

      #
      # Worker Thread
      #

      def enqueue(*args, &block)
        @queue << [args, block]
        start_worker
      end

      def dequeue(sleep_time)
        @queue.shift(sleep_time)
      rescue TimeoutQueue::ClosedQueueError
        raise StopIteration
      end

      def start_worker
        @worker.try_set { Thread.new { worker_loop } }
      end

      def stop_worker
        @queue.close
        @stopped.wait
      end

      def worker_loop
        @engine.worker.with_error_handler do
          loop do
            sleep_time = heartbeat
            args, block = dequeue(sleep_time)
            block.call(*args) if block
          end
          @stopped.set
        end
      end

      def heartbeat
        now = Time.now.to_i
        @next_heartbeat ||= now + @heartbeat_interval
        return @next_heartbeat - now if @next_heartbeat > now

        update_tasks

        @next_heartbeat += @heartbeat_interval
        @heartbeat_interval
      end
    end
  end
end

module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine

        @queue = TimeoutQueue.new
        @worker = Concurrent::IVar.new

        @task_operators = {}
        @jobflow_status = {}
        initialize_with_tasks

        @heartbeat_interval = 0.1
        @next_heartbeat = nil
        @complete = Concurrent::Event.new
        @stopped = Concurrent::Event.new
        @killed = Concurrent::Event.new
      end

      def submit(task_name, time)
        enqueue { post_task(task_name, time) }
      end

      def complete?
        @task_operators.each_value.all?(&:complete?) \
        && !@jobflow_status.each_value.any?(&:next?)
      end

      # This is for testing.
      # It may cause deadlock if there is lag | align triggers.
      def wait_complete(timeout = nil)
        @complete.wait(timeout)
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
        @complete.set
        @killed.set
      end

      private

      def initialize_with_tasks
        Sorge.tasks.each do |task_name, _|
          @task_operators[task_name] = TaskOperator.new(@engine, task_name)
          @jobflow_status[task_name] = TaskStatus.new.freeze!
        end
        @jobflow_status.freeze
      end

      def post_task(task_name, time)
        task_operator = @task_operators[task_name]
        st = task_operator.post(time, @jobflow_status)
        @jobflow_status = @jobflow_status.merge(task_name => st).freeze
      end

      def update
        update_tasks
        complete? ? @complete.set : @complete.reset
      end

      def update_tasks
        next_jobflow_status = {}

        @task_operators.each do |task_name, task_operator|
          next_jobflow_status[task_name] =
            task_operator.update(@jobflow_status)
        end

        @jobflow_status = next_jobflow_status.freeze
        # TODO: savepoint.update(jobflow_status)
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

        update

        @next_heartbeat += @heartbeat_interval
        @heartbeat_interval
      end
    end
  end
end

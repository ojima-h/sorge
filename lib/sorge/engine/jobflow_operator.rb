module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine

        @queue = TimeoutQueue.new
        @worker = Concurrent::IVar.new

        @task_operators = collect_task_operators
        @finished_tasks = {}

        @heartbeat_interval = 0.1
        @next_heartbeat = nil
        @stopped = Concurrent::Event.new
      end

      def submit(task_name, time)
        enqueue do
          @task_operators[task_name].post(time)
        end
      end

      def invoke(task_name, time)
        @task_operators[task_name].post(time)
        sleep(heartbeat) until @task_operators.values.all?(&:complete?) \
                               && @finished_tasks.values.all?(&:empty?)
      end

      def shutdown
        stop_worker
        @task_operators.each_value(&:shutdown)
      end

      def wait_for_termination
        @task_operators.each_value(&:wait_for_termination)
      end

      private

      def collect_task_operators
        ret = {}
        Sorge.tasks.each do |task_name, _|
          ret[task_name] = TaskOperator.new(@engine, task_name)
        end
        ret
      end

      def update_tasks
        next_finished_tasks = {}
        tasks_status = {}

        @task_operators.each do |task_name, task_operator|
          status, finished = task_operator.update(@finished_tasks)
          next_finished_tasks[task_name] = finished
          tasks_status[task_name] = status
        end

        @finished_tasks = next_finished_tasks
        # TODO: savepoint.update(tasks_status)
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

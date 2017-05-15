module Sorge
  class Engine
    class JobflowOperator
      Submit = Struct.new(:task_name, :time)

      def initialize(engine)
        @engine = engine
        @heartbeat_interval = 0.1

        @task_operators = {}
        @jobflow_status = JobflowStatus.new
        initialize_with_tasks

        @worker = AsyncWorker.new(@engine)
        @timer = create_timer

        @complete = Concurrent::Event.new
        @stopped = Concurrent::Event.new
        @killed = Concurrent::Event.new
      end

      def start
        @timer.execute
      end

      def submit(task_name, time)
        @worker.post { post_task(task_name, time) }
        @timer.execute
      end

      def resume(data)
        @jobflow_status = JobflowStatus.restore(data)
        @task_operators.each do |task_name, task_operator|
          task_operator.resume(@jobflow_status[task_name])
        end
        @timer.execute
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
        @timer.shutdown
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

      def create_timer
        Concurrent::TimerTask.new(
          execution_interval: @heartbeat_interval
        ) do
          @engine.worker.with_error_handler do
            @worker.post do
              update
            end
          end
        end
      end

      def initialize_with_tasks
        Sorge.tasks.each_task do |task_name, _|
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
        @engine.savepoint.save(@jobflow_status.dump)
        complete? ? @complete.set : @complete.reset
      end

      def update_tasks
        next_jobflow_status = JobflowStatus.new

        @task_operators.each do |task_name, task_operator|
          next_jobflow_status[task_name] =
            task_operator.update(@jobflow_status)
        end

        @jobflow_status = next_jobflow_status.freeze
      end
    end
  end
end

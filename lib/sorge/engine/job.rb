module Sorge
  class Engine
    class Job
      def initialize(engine, task, num_waiting)
        @engine = engine
        @task = task
        initialize_agent(num_waiting)
      end

      def status
        @agent.value
      end

      def invoke(params)
        @agent.send(params) do |_, my_params|
          JobStatus::Pending.new(params: my_params)
        end
      end

      def inspect
        format('#<%s:0x00%x task=%s status=%s>',
               self.class,
               object_id << 1,
               @task.inspect,
               status.inspect)
      end

      def update_status(message, *args)
        @agent.send(message, *args) do |status, my_message, *my_args|
          status.send(my_message, *my_args)
        end
      end

      # status agent observer
      def on_status_updated(_time, old_status, new_status)
        return if old_status == new_status

        on_pending(new_status) if new_status.pending?
        on_complete(new_status) if new_status.complete?
      end

      private

      def initialize_agent(num_waiting)
        status = JobStatus::Unscheduled.new(num_waiting: num_waiting)
        @agent = Concurrent::Agent.new(
          status,
          error_handler: ->(_, error) { log_error(self, error) }
        )
        @agent.add_observer(self, :on_status_updated)
      end

      def on_pending(status)
        @engine.worker.post_job(status.params, &method(:execute))
      end

      def on_complete(status)
        @engine.job_manager.notify_finish(self)
        notify_to_successors(status)
      end

      def execute(params = {})
        t = @task.new(params)

        Sorge.logger.info("start: #{t}")
        update_status(:start, t.params)
        t.execute

        Sorge.logger.info("successed: #{t}")
        update_status(:successed)
      rescue => error
        log_error(t, error)
        update_status(:failed, error)
      end

      def notify_to_successors(status)
        @task.successors.each do |succ|
          @engine.job_manager[succ.name]
                 .update_status(:predecessor_finished, status)
        end
      end

      def log_error(name, error)
        Sorge.logger.error("failed: #{name}")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))
      end
    end
  end
end

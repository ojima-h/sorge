module Sorge
  class Engine
    class Job
      def initialize(engine, batch, task, num_waiting)
        @engine = engine
        @batch = batch
        @task = task
        @status = if num_waiting > 0
                    JobStatus::Unscheduled.new(num_waiting: num_waiting)
                  else
                    JobStatus::Pending.new
                  end
      end
      attr_reader :task, :status

      def inspect
        format('#<%s:0x00%x task=%s status=%s>',
               self.class,
               object_id << 1,
               @task.inspect,
               status.inspect)
      end

      def successors
        @task.successors.map { |succ| @batch.jobs[succ.name] }
      end

      def update(message, *args)
        @status = status.send(message, *args)
      end

      def invoke(params = {})
        @engine.executor.post(self, params)
      end

      def execute(params)
        t = @task.new(params)

        Sorge.logger.info("start: #{t}")
        @batch.update(self, :start, t.params)
        t.execute

        Sorge.logger.info("successed: #{t}")
        @batch.update(self, :successed)
      rescue => error
        log_error(t, error)
        @batch.update(self, :failed, error)
      end

      def log_error(name, error)
        Sorge.logger.error("failed: #{name}")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))
      end

      def stash
        @engine.stash[@task.name]
      end
    end
  end
end

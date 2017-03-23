module Sorge
  class Engine
    class Job
      def initialize(engine, batch, task, num_waiting, params = {})
        @engine = engine
        @batch = batch
        @task = task
        @task_instance = task.new(self)
        @params = params

        @status = if num_waiting > 0
                    JobStatus::Unscheduled.new(num_waiting: num_waiting)
                  else
                    JobStatus::Pending.new
                  end
      end
      attr_reader :task, :params, :status

      #
      # Attributes
      #

      def stash
        @engine.stash[@task.name]
      end

      def successors
        @successors ||= @task.successors.map { |succ| @batch.jobs[succ.name] }
      end

      def upstreams
        @upstreams ||=
          @task.upstreams.map do |up, _|
            [up.name, @batch.jobs[up.name]] if @batch.jobs.include?(up.name)
          end.compact.to_h
      end

      def inspect
        format('#<%s:0x00%x task=%s status=%s>',
               self.class,
               object_id << 1,
               @task.inspect,
               status.inspect)
      end

      #
      # Actions
      #

      def update(message, *args)
        @status = status.send(message, *args)
      end

      def invoke
        @engine.executor.post(self)
      end

      def execute
        setup
        start

        successed
      rescue => error
        failed(error)
      end

      private

      def setup
        @task_instance.setup
      end

      def start
        Sorge.logger.info("start: #{@task_instance}")
        @batch.update(self, :start, params)
        @task_instance.execute
      end

      def successed
        Sorge.logger.info("successed: #{@task_instance}")
        @batch.update(self, :successed)
      end

      def failed(error)
        Sorge.logger.error("failed: #{@task.name}")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))

        @batch.update(self, :failed, error)
      end
    end
  end
end

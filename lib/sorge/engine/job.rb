module Sorge
  class Engine
    class Job
      Context = Struct.new(:batch, :job)

      def initialize(engine, batch, task, num_waiting, params = {})
        @engine = engine
        @batch = batch
        @task = task
        @task_instance = task.new(Context[@batch, self])
        @params = params

        @start_time = nil
        @end_time = nil
        @error = nil

        @status = JobStatus.unscheduled(num_waiting)
      end
      attr_reader :task, :task_instance, :params,
                  :status, :start_time, :end_time, :error

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
        @status = status.step(message, *args)
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
        @batch.update(self, :start)
        @start_time = Time.now
        @task_instance.execute
      end

      def successed
        Sorge.logger.info("successed: #{@task_instance}")
        @end_time = Time.now
        @batch.update(self, :successed)
      end

      def failed(error)
        Sorge.logger.error("failed: #{@task.name}")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))

        @end_time = Time.now
        @error = error
        @batch.update(self, :failed)
      end
    end
  end
end

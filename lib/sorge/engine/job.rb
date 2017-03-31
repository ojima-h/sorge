module Sorge
  class Engine
    class Job
      Context = Struct.new(:jobflow, :job)

      def initialize(engine, jobflow, task, num_waiting, params = {})
        @engine = engine
        @jobflow = jobflow

        @task = task
        @task_instance = task.new(Context[@jobflow, self])
        @params = params
        @stash = nil

        @status = JobStatus.unscheduled(num_waiting)
        @start_time = nil
        @end_time = nil
        @error = nil
      end
      attr_reader :task, :task_instance, :params, :stash,
                  :status, :start_time, :end_time, :error

      #
      # Attributes
      #

      def successors
        @successors ||= @task.successors.map { |succ| @jobflow.jobs[succ.name] }
      end

      def visit_reachable_edges
        @task.visit_reachable_edges do |edge|
          head = @jobflow.jobs[edge.head.name]
          tail = @jobflow.jobs[edge.tail.name]
          yield head, tail
        end
      end

      def upstreams
        @upstreams ||=
          @task.upstreams.map do |up, _|
            [up.name, @jobflow.jobs[up.name]] if @jobflow.jobs.include?(up.name)
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
        old_status = @status
        @status = @status.step(message, *args)
        [old_status, @status]
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
        @stash = @engine.state_manager.fetch(@task.name)
        @task_instance.setup
      end

      def start
        Sorge.logger.info("start: #{@task_instance}")
        @jobflow.update(self, :start)
        @start_time = Time.now
        @task_instance.execute
      end

      def successed
        Sorge.logger.info("successed: #{@task_instance}")
        @end_time = Time.now
        @jobflow.update(self, :successed)
      end

      def failed(error)
        Sorge.logger.error("failed: #{@task.name}")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))

        @end_time = Time.now
        @error = error
        @jobflow.update(self, :failed)
      end
    end
  end
end

module Sorge
  class Engine
    class Batch
      # entire batch status
      class Summary
        def initialize(jobs)
          @status = Hash.new { |h, k| h[k] = 0 }
          jobs.each { |_, job| @status[job.status.name] += 1 }
          @errors = []
          @pending_jobs = jobs.length
        end
        attr_reader :status, :errors, :pending_jobs

        def update(old_status, new_status)
          @status[old_status.name] -= 1
          @status[new_status.name] += 1

          @errors << new_status.error if new_status.failed?

          @pending_jobs -= 1 if new_status.complete?
        end
      end

      def initialize(engine)
        @engine = engine
        @jobs = {}
        @summary = nil

        @event = Concurrent::Event.new
        @mtx = Mutex.new
      end
      attr_reader :jobs, :summary

      def start(root_task, params)
        initialize_jobs(root_task)
        @jobs[root_task.name].invoke(params)
      end

      def update(job, message, *args)
        changed, next_jobs = update_jobs(job, message, *args)

        return unless changed

        @event.set if @summary.pending_jobs <= 0
        next_jobs.each(&:invoke)
      end

      def wait(timeout = nil)
        @event.wait(timeout)
        self
      end

      private

      def initialize_jobs(root_task)
        @engine.task_graph.reachable_edges(root_task)
               .group_by(&:tail)
               .each do |task, edges|
                 @jobs[task.name] = Job.new(@engine, self, task, edges.count)
               end
        @jobs[root_task.name] = Job.new(@engine, self, root_task, 0)
        @summary = Summary.new(@jobs)
      end

      def update_jobs(job, message, *args)
        @mtx.synchronize do
          next_jobs = []
          ret = update_job_with_successors(job, message, *args) do |next_job|
            next_jobs << next_job
          end
          [ret, next_jobs]
        end
      end

      def update_job(job, message, *args)
        old_status = job.status
        job.update(message, *args)
        new_status = job.status

        return false if old_status == new_status

        @summary.update(old_status, new_status)

        true
      end

      def update_job_with_successors(job, message, *args, &block)
        return unless update_job(job, message, *args)

        yield job if job.status.pending?

        if job.status.complete?
          job.successors.each do |succ|
            update_job_with_successors(succ, :predecessor_finished, job.status,
                                       &block)
          end
        end

        true
      end
    end
  end
end

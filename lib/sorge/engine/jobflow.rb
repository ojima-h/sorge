module Sorge
  class Engine
    class Jobflow
      # entire jobflow status
      class Summary
        def initialize(jobs)
          @status = Hash.new { |h, k| h[k] = 0 }
          jobs.each { |_, job| @status[job.status.name] += 1 }
          @errors = []
          @active_jobs = jobs.length
        end
        attr_reader :status, :errors, :active_jobs

        def update(old_status, new_status, error = nil)
          @status[old_status.name] -= 1
          @status[new_status.name] += 1

          @errors << error if new_status.failed? && !error.nil?

          @active_jobs -= 1 if new_status.complete?
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
        initialize_jobs(root_task, params)
        @jobs[root_task.name].invoke
      end

      def update(job, message, *args)
        next_jobs = update_jobs(job, message, *args)
        @event.set if @summary.active_jobs <= 0
        next_jobs.each(&:invoke)
      end

      def wait(timeout = nil)
        @event.wait(timeout)
        self
      end

      private

      def initialize_jobs(root_task, params)
        root_task.reachable_edges
                 .group_by(&:tail)
                 .each do |task, edges|
                   @jobs[task.name] = Job.new(@engine, self, task, edges.count)
                 end
        @jobs[root_task.name] = Job.new(@engine, self, root_task, 0, params)
        @summary = Summary.new(@jobs)
      end

      def update_jobs(job, message, *args)
        @engine.state_manager.synchronize do
          ret = update_job(job, message, *args)
          return [] unless ret && job.status.complete?
          @engine.state_manager.update(job.task.name, job.stash)
          update_successors(job)
        end
      end

      def update_job(job, message, *args)
        old_status, new_status = job.update(message, *args)
        return false if old_status == new_status

        @summary.update(old_status, new_status, job.error)
        true
      end

      def update_successors(job)
        next_jobs = []
        job.visit_reachable_edges do |_, succ|
          next unless update_job(succ, :predecessor_finished, job.status)
          next_jobs << succ if succ.status.pending?
          succ.status.complete?
        end
        next_jobs
      end
    end
  end
end

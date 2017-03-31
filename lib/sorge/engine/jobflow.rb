module Sorge
  class Engine
    class Jobflow
      def initialize(driver)
        @driver = driver
        @engine = driver.engine
        @id = Time.now.strftime('%Y%m%d%H%M%S-') + Util.generate_id

        @jobs = {}
        @status = Hash.new { |hash, key| hash[key] = 0 }
        @errors = []
        @active_jobs = 0

        @event = Concurrent::Event.new
        @mtx = Mutex.new
      end
      attr_reader :id, :engine, :jobs

      def add(task, status, params = {})
        @jobs[task.name] = Job.new(self, task, status, params)
        @status[status.name] += 1
        @active_jobs += 1
        @jobs[task.name]
      end

      def start(root_task)
        @jobs[root_task.name].invoke
      end

      def update(job, message, *args)
        next_jobs = update_jobs(job, message, *args)
        return if complete?
        next_jobs.each(&:invoke)
      end

      def complete?
        @event.set?
      end

      def failed?
        complete? && @status['failed'] > 0
      end

      def wait(timeout = nil)
        @event.wait(timeout)
        self
      end

      def kill
        @engine.state_manager.synchronize do
          @jobs.each { |_, job| update_job(job, :kill) }
        end
      end

      private

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

        update_status(old_status, new_status, job.error)
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

      def update_status(old_status, new_status, error = nil)
        @status[old_status.name] -= 1
        @status[new_status.name] += 1

        @errors << error if new_status.failed? && !error.nil?

        @active_jobs -= 1 if new_status.complete?
        finish if @active_jobs <= 0
      end

      def finish
        save
        @event.set
        @engine.driver.update(self)
      end

      # Save failed jobs to snapshot file.
      def save
        jobs = []
        @jobs.each do |_, job|
          next unless job.status.failed?
          jobs << { 'name' => job.task.name, 'params' => job.params }
        end
        return if jobs.empty?
        @engine.savepoint.put_jobflow(id, jobs)
      end
    end
  end
end

module Sorge
  class Engine
    class TaskRunner
      def initialize(engine)
        @engine = engine
        @agent = {}
        @running = {}
      end
      attr_reader :running

      def post(job)
        job_id = Util.generate_id
        @running[job_id] = job.to_h

        async(assign_agent(job.name), job_id, job, &method(:run))
      end

      def complete(job_id)
        @running.delete(job_id)
      end

      def empty?
        @running.empty?
      end

      def resume(running, finished)
        running.each do |job_id, job_hash|
          next if finished.include?(job_id)
          post(TaskHandler.restore_job(@engine, job_hash))
        end
      end

      private

      def async(agent, *args, &block)
        @engine.worker.post_agent(agent, *args, &block)
      end

      def assign_agent(task_name)
        @agent[task_name] ||= @engine.worker.new_agent
      end

      def run(job_id, job)
        result = job.invoke
        m = result ? :successed : :failed
        @engine.event_queue.submit(m, job_id: job_id, **job.to_h)
      end
    end
  end
end

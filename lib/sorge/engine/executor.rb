module Sorge
  class Engine
    class Executor
      def initialize(engine)
        @engine = engine
        @mutex = Mutex.new
        @queue = {}
      end

      def post(job)
        assign_queue(job).send_via!(@engine.worker.job_worker,
                                    job, &method(:safe_execute))
      end

      private

      def assign_queue(job)
        unless @queue.include?(job.task.name)
          @mutex.synchronize do
            @queue[job.task.name] ||= Concurrent::Agent.new(nil)
          end
        end
        @queue[job.task.name]
      end

      def send_queue(job, *args, &block)
        assign_queue(job)
          .send_via!(@engine.worker.job_worker, job, *args, &block)
      end

      def safe_execute(_, job)
        @engine.worker.capture_exception do
          job.execute
        end
      end
    end
  end
end

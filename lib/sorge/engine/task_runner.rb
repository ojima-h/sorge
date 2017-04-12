module Sorge
  class Engine
    class TaskRunner
      def initialize(engine)
        @engine = engine
        @agent = {}
        @running = Hash.new { |hash, key| hash[key] = [] }
        @counter = 0
      end
      attr_reader :running

      def post(job)
        @running[job.name] << job.to_h
        @counter += 1

        async(assign_agent(job.name), job, &method(:run))
      end

      def complete(task_name)
        @running[task_name].shift
        @running.delete(task_name) if @running[task_name].empty?
        @counter -= 1
      end

      def empty?
        @counter.zero?
      end

      private

      def async(agent, *args)
        worker = @engine.worker.task_worker
        agent.send_via!(worker, *args) do |_, *my_args|
          @engine.worker.capture_exception do
            yield(*my_args)
          end
          nil
        end
      end

      def assign_agent(task_name)
        @agent[task_name] ||= Concurrent::Agent.new(nil)
      end

      def run(job)
        result = job.invoke
        return unless result

        @engine.event_queue.submit(:complete, job.to_h)
      end
    end
  end
end

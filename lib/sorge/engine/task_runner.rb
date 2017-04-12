module Sorge
  class Engine
    class TaskRunner
      def initialize(engine)
        @engine = engine
        @agent = {}
        @running = Hash.new { |hash, key| hash[key] = [] }
      end
      attr_reader :running

      def post(job)
        Engine.synchronize { @running[job.name] << job.to_h }

        async(assign_agent(job.name), job, &method(:run))
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
        unless @agent.include?(task_name)
          Engine.synchronize do
            @agent[task_name] ||= Concurrent::Agent.new(nil)
          end
        end
        @agent[task_name]
      end

      def run(job)
        result = job.invoke

        Engine.synchronize do
          @running[job.name].shift
          @engine.event_queue.submit(:complete, job.to_h) if result
        end
      end
    end
  end
end

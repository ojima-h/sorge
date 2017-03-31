module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @jobflows = {}
      end
      attr_reader :engine, :jobflows

      # Invoke task asynchronously
      def invoke(task, params)
        jobflow = JobflowBuilder.build(self, task, params)
        @jobflows[jobflow.id] = jobflow
        jobflow.start(task)
        jobflow
      end

      # Run task synchronously
      def run(task, params)
        @engine.worker.capture_exception do
          invoke.wait(task, params)
        end
      end

      def update(jobflow)
        return unless jobflow.complete?
        @jobflows.delete(jobflow.id)
      end

      def kill
        @jobflows.each { |_, j| j.kill }
      end
    end
  end
end

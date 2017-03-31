module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @jobflows = {}
      end
      attr_reader :engine, :jobflows

      def invoke(task, params)
        jobflow = JobflowBuilder.build(self, task, params)
        @engine.state_manager.synchronize do
          @jobflows[jobflow.id] = jobflow
        end
        jobflow.start(task)
        jobflow
      end

      def update(jobflow)
        return unless jobflow.complete?
        @engine.state_manager.synchronize do
          @jobflows.delete(jobflow.id)
        end
      end
    end
  end
end

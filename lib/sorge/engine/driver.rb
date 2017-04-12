module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
        @jobflows = {}
        @finish_event = Concurrent::Event.new
        @error = nil
      end
      attr_reader :engine, :jobflows

      # Invoke task asynchronously
      def invoke(task, params)
        @engine.savepoint.start

        jobflow = JobflowBuilder.build(self, task, params)
        @jobflows[jobflow.id] = jobflow
        jobflow.start(task)
        jobflow
      end

      # Run task synchronously
      def run(task_name, time)
        @engine.event_queue.submit(:run, name: task_name, time: time)
        shutdown
      end

      def shutdown
        @engine.savepoint.stop
        @finish_event.wait
        raise @error if @error
      end

      def task_finished
        return unless @engine.event_queue.empty? && @engine.task_runner.empty?
        @finish_event.set
      end

      def update(jobflow)
        return unless jobflow.complete?
        @jobflows.delete(jobflow.id)
      end

      def kill(error)
        @error = error
        @finish_event.set
        @jobflows.each { |_, j| j.kill }
      end
    end
  end
end

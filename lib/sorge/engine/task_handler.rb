module Sorge
  class Engine
    class TaskHandler
      extend Forwardable

      def initialize(engine, task_name)
        @engine = engine
        @task = @engine.application.dsl.task_manager[task_name]
        @state = @engine.task_states[@task_name]
      end

      def notify(name, time)
        @state[:window] ||= {}

        tms = @task.window_handler.update(@state[:window], name, time)

        tms.each { |tm| @engine.event_queue.submit :run, time: tm }
      end

      def run(time)
        @task.new(Context[time, job]).execute
      end
    end
  end
end

module Sorge
  class Engine
    class TaskHandler
      extend Forwardable

      Context = Struct.new(:time, :state)

      # TODO: DELETE
      Context.send(:define_method, :job) { Struct.new(:stash, :params)[{}, {}] }

      def initialize(engine, task_name)
        @engine = engine
        @task = @engine.application.dsl.task_manager[task_name]
        @state = @engine.task_states[task_name]
      end

      def notify(name, time)
        @state[:window] ||= {}

        tms = @task.window_handler.update(@state[:window], name, time)

        tms.each do |tm|
          @engine.task_runner.post(@task, build_context(tm))
        end
      end

      private

      def build_context(time)
        Context[time, build_task_state]
      end

      def build_task_state
        return {} unless @state.include?(:task)

        Marshal.load(Marshal.dump(@state[:task])) # deep copy
      rescue => error
        Sorge.logger.warn("error:\n" + Util.format_error_info(error))
        {}
      end
    end
  end
end

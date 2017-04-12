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

        tms.each { |tm| run(tm) }
      end

      def run(time)
        @engine.task_runner.post(create_job(time))
      end

      def complete(time, state)
        @state[:task] = state

        @task.successors.each do |succ|
          params = { name: @task.name, time: time, dest: succ.name }
          @engine.event_queue.submit(:notify, params)
        end
      end

      private

      def create_job(time)
        @task.new(Context[time, build_task_state])
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

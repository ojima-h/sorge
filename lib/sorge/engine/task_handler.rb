module Sorge
  class Engine
    class TaskHandler
      extend Forwardable

      Context = Struct.new(:app, :time, :state)

      # TODO: DELETE
      Context.send(:define_method, :job) { Struct.new(:stash, :params)[{}, {}] }

      def initialize(engine, task_name)
        @engine = engine
        @task = DSL.instance[task_name]
        @state = @engine.task_states[task_name]
      end

      def notify(name, time)
        @state[:window] ||= {}

        tms = @task.window_handler.update(@state[:window], name, time)

        tms.each(&method(:run))
      end

      def run(time)
        @engine.task_runner.post(to_job(time))
      end

      def failed(job_id, _time, _state)
        @engine.task_runner.complete(job_id)
      end

      def successed(job_id, time, state)
        @engine.task_runner.complete(job_id)

        @state[:task] = state

        Util.assume_array(time).each(&method(:broadcast))
      end

      def broadcast(time)
        @task.successors.each do |succ|
          params = { name: @task.name, time: time, dest: succ.name }
          @engine.event_queue.submit(:notify, params)
        end
      end

      def self.restore_job(engine, hash)
        task = DSL.instance[hash[:name]]
        task.new(Context[engine.application, hash[:time], hash[:state]])
      end

      def to_job(time)
        @task.new(Context[@engine.application, time, build_task_state])
      end

      private

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

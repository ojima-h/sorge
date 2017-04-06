module Sorge
  class Engine
    class TaskState
      extend Forwardable

      def initialize(engine, task_name)
        @engine = engine
        @task_name = task_name

        @hash = nil
      end
      def_delegators :@hash, :[], :[]=

      def init
        @hash = @engine.state_manager.fetch(@task_name)
      end

      def save
        @engine.state_manager.update(@task_name, @hash)
        @hash = nil
      end

      def update
        init
        yield self
        save
      end

      def queue
        @hash[:queue] ||= []
      end
    end
  end
end

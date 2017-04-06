module Sorge
  class Engine
    class TaskState
      extend Forwardable

      def initialize(engine, task_name)
        @engine = engine
        @task_name = task_name

        @hash = nil
        @open = false
      end
      def_delegators :@hash, :[], :[]=

      def session
        return yield if @open
        @open = true

        read
        ret = yield
        save

        ret
      ensure
        @open = false
      end

      def queue
        @hash[:q] ||= []
      end

      def watermarks
        @hash[:wm] ||= {}
      end

      private

      def read
        @hash = @engine.state_manager.fetch(@task_name)
      end

      def save
        @engine.state_manager.update(@task_name, @hash)
        @hash = nil
      end
    end
  end
end

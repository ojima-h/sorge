module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
      end

      def invoke(task, params)
        @engine.job_manager.prepare(task)
        @engine.job_manager[task.name].invoke(params)
        @engine.job_manager.wait
      end
    end
  end
end

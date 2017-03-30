module Sorge
  class Engine
    class Driver
      def initialize(engine)
        @engine = engine
      end

      def invoke(task, params)
        jobflow = Jobflow.new(@engine)
        jobflow.start(task, params)
        jobflow
      end
    end
  end
end

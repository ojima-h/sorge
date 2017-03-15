module Sorge
  class Engine
    class JobManager
      def initialize(engine)
        @engine = engine
        @latch = nil
        @jobs = nil
      end

      def [](task_name)
        @jobs[task_name]
      end

      def prepare(root_task)
        @jobs = {}
        @engine.task_graph.reachable_edges(root_task)
               .group_by(&:tail)
               .each do |task, edges|
                 @jobs[task.name] = Job.new(@engine, task, edges.count)
               end
        @jobs[root_task.name] = Job.new(@engine, root_task, 0)

        @latch = Concurrent::CountDownLatch.new(@jobs.length)
      end

      def notify_finish(_job)
        @latch.count_down
      end

      def wait(timeout = nil)
        @latch.wait(timeout)
      end
    end
  end
end

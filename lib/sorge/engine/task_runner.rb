module Sorge
  class Engine
    class TaskRunner
      def initialize(engine)
        @engine = engine
        @queue = {}
        @running = {}
      end
      attr_reader :running

      def post(task, context)
        q = assign_queue(task.name)
        worker = @engine.worker.task_worker

        q.send_via!(worker, task, context) do |_, *my_args|
          @engine.worker.capture_exception do
            run(*my_args)
          end
          nil
        end
      end

      private

      def assign_queue(task_name)
        unless @queue.include?(task_name)
          Engine.synchronize do
            @queue[task_name] ||= Concurrent::Agent.new(nil)
          end
        end
        @queue[task_name]
      end

      def run(task, context)
        id = Util.generate_id
        task_instance = task.new(context)

        Engine.synchronize { @running[id] = task_instance.to_h }

        task_instance.invoke && finish(task_instance)
      ensure
        Engine.synchronize { @running.delete(id) }
      end

      def finish(task_instance)
        @engine.event_queue.submit(:complete, task_instance.to_h)
      end
    end
  end
end

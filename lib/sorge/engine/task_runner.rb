module Sorge
  class Engine
    class TaskRunner
      def initialize(engine)
        @engine = engine
        @mutex = Mutex.new
        @queue = {}
        @running = {}
      end

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
          @mutex.synchronize do
            @queue[task_name] ||= Concurrent::Agent.new(nil)
          end
        end
        @queue[task_name]
      end

      def run(task, context)
        id = Util.generate_id
        @mutex.synchronize { @running[id] = [task, context] }

        safe_execute(task, context)
      ensure
        @mutex.synchronize { @running.delete(id) }
      end

      def safe_execute(task, context)
        task.new(context).execute

        successed(task, context)

        finish(task, context)
      rescue => error
        failed(task, context, error)
      end

      def successed(task, context)
        Sorge.logger.info("successed: #{task.name} (#{context.time})")
      end

      def failed(task, context, error)
        Sorge.logger.error("failed: #{task.name} (#{context.time})")
        Sorge.logger.error("error:\n" + Util.format_error_info(error))
      end

      def finish(task, context)
        params = { name: task.name, time: context.time, state: context.state }
        @engine.event_queue.submit(:complete, params)
      end
    end
  end
end

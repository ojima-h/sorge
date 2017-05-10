module Sorge
  class Engine
    class TaskOperator
      Context = Struct.new(:app, :time, :state) do
        def job
          Struct.new(:stash, :params)[{}, {}]
        end
      end

      Status = Struct.new(:state, :queue)

      def initialize(engine, task_name)
        @engine = engine
        @task = DSL.instance[task_name]

        @state = {}
        @pending = []
        @running = []
        @finished = []
        @mutex = Mutex.new
      end

      def post(time)
        @mutex.synchronize do
          ns_enqueue(time)
          ns_collect_status
        end
      end

      def update(finished_tasks = {})
        @mutex.synchronize do
          @task.upstreams.each do |task_name, _|
            ns_enqueue(*finished_tasks[task_name])
          end
          ns_collect_status
        end
      end

      def resume(times, state)
        @mutex.synchronize do
          @state = state
          ns_enqueue(*times)
        end
      end

      private

      def ns_enqueue(*times)
        ns_merge_pending(*times)

        ready = ns_collect_ready
        return if ready.empty?

        @running += ready
        @engine.worker.post { perform } if @running.length == ready.length
      end

      def ns_merge_pending(*times)
        time_truncs = times.map { |time| @task.time_trunc.call(time) }
        @pending = (@pending + time_truncs).uniq
      end

      def ns_collect_ready
        ready, @pending = @task.trigger.call(@pending)
        ready
      end

      def perform
        time = @mutex.synchronize { @running.first }
        return if time.nil?

        execute(time)

        @mutex.synchronize do
          @running = @running[1..-1]
          @finished += [time]
          @engine.worker.post { perform } unless @running.empty?
        end
      end

      def execute(time)
        context = Context[@engine.application, time, @state.dup]
        @task.new(context).invoke
        @mutex.synchronize { @state = context.state }
      end

      def ns_collect_status
        status = Status[@state, @pending + @running]
        finished = @finished
        @finished = []

        [status, finished]
      end
    end
  end
end

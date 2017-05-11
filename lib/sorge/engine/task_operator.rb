module Sorge
  class Engine
    class TaskOperator
      Context = Struct.new(:app, :time, :state) do
        def job
          Struct.new(:stash, :params)[{}, {}]
        end
      end

      def initialize(engine, task_name)
        @engine = engine
        @task = DSL.instance[task_name]

        @state = {}
        @trigger_state = {}
        @pending = []
        @running = []
        @finished = []
        @position = 0

        @mutex = Mutex.new
        @stop = false
        @stopped = Concurrent::Event.new
      end

      def complete?
        @mutex.synchronize do
          @stop || [@pending, @running, @finished].all?(&:empty?)
        end
      end

      def post(time)
        @mutex.synchronize do
          ns_enqueue(time)
          ns_collect_status
        end
      end

      def update(jobflow_context)
        @mutex.synchronize do
          times = @task.upstreams.map do |task_name, _|
            jobflow_context[task_name].finished
          end.flatten
          ns_enqueue(*times)
          ns_collect_status
        end
      end

      def resume(times, state)
        @mutex.synchronize do
          @state = state
          ns_enqueue(*times)
        end
      end

      def shutdown
        @mutex.synchronize do
          @stop = true
          @stopped.set if @running.empty?
        end
      end

      def wait_for_termination(timeout = nil)
        @stopped.wait(timeout)
      end

      def kill
        @stop = true
        @stopped.set
      end

      private

      def ns_enqueue(*times)
        raise AlreadyStopped if @stop
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
        return @stopped.set if @stop

        time = @mutex.synchronize { @running.first }
        return if time.nil?

        execute(time)

        @mutex.synchronize do
          @running = @running[1..-1]
          @finished += [time]
          @position = [@position, time].max
          @engine.worker.post { perform } unless @running.empty?
        end
      end

      def execute(time)
        context = Context[@engine.application, time, @state.dup]
        @task.new(context).invoke
        @mutex.synchronize { @state = context.state }
      end

      def ns_collect_status
        status = ns_build_status
        @finished = []
        status
      end

      def ns_build_status
        TaskStatus[
          @state,
          @trigger_state,
          @pending,
          @running,
          @finished,
          @position
        ].freeze!
      end
    end
  end
end

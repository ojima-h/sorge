module Sorge
  class Engine
    class TaskOperator
      extend Forwardable

      Event = Struct.new(:task_name, :time)
      TaskResult = Struct.new(:successed?, :state, :emitted)
      TriggerContext = Struct.new(:state, :jobflow_status)

      def initialize(engine, task_name)
        @engine = engine
        @task = @engine.app.tasks[task_name]

        @state = {}
        @trigger_state = {}
        @pending = PaneSet.new
        @running = nil
        @finished = []
        @position = Time.at(0)

        @worker = AsyncWorker.new(@engine, @task.worker)
        @mutex = Mutex.new
        @lock = Concurrent::ReadWriteLock.new
      end
      def_delegators :@lock, :acquire_read_lock, :release_read_lock

      def post(time, jobflow_status)
        @mutex.synchronize do
          ns_enqueue([Event[nil, time]], jobflow_status)
          ns_collect_status
        end
      end

      def resume(task_status)
        @mutex.synchronize do
          @state         = task_status.state
          @trigger_state = task_status.trigger_state
          @pending       = task_status.pending
          @running       = task_status.running
          @finished      = task_status.finished
          @position      = task_status.position

          @worker.post { perform } if @running
        end
      end

      def flush
        @mutex.synchronize do
          return if @pending.empty?
          return if @running

          target, *rest = @pending.panes
          @pending = PaneSet[*rest]
          @running = target

          @worker.post { perform }

          ns_collect_status
        end
      end

      def stop
        @worker.stop
      end

      def wait_stop
        @worker.wait_stop
        @mutex.synchronize { ns_collect_status }
      end

      def kill
        @worker.kill
      end

      def update(jobflow_status)
        @mutex.synchronize do
          events = []
          @task.upstreams.each do |task_name, _|
            jobflow_status[task_name].finished.each do |time|
              events << Event[task_name, time]
            end
          end
          ns_enqueue(events, jobflow_status)
          ns_collect_status
        end
      end

      private

      def ns_enqueue(events, jobflow_status)
        ns_append_events(events)

        return if @running

        target = ns_shift_pending(jobflow_status)
        return if target.nil?

        @running = target
        @worker.post { perform }
      end

      def ns_append_events(events)
        events.each do |event|
          time = @task.time_trunc.call(event.time)
          @pending = @pending.add(time, event.task_name)
        end
      end

      def ns_shift_pending(jobflow_status)
        context = TriggerContext[@trigger_state.dup, jobflow_status]
        ready, pending = @task.trigger.call(@pending.panes, context)
        target, *rest = ready
        @pending = PaneSet[*rest, *pending]
        @trigger_state = context.state
        target
      end

      def perform
        # result = execute(@running)
        result = with_lock { execute(@running) }

        @mutex.synchronize { ns_update_status(result) }
      end

      def execute(pane)
        context = DSL::TaskContext[pane.time, @state.dup, pane, @position]
        task_instance = @task.new(context)
        result = task_instance.invoke
        TaskResult[result, context.state, task_instance.emitted]
      end

      def ns_update_status(result)
        @state = result.state
        time = @running.time
        @running = nil

        return unless result.successed?

        @finished += result.emitted.empty? ? [time] : result.emitted
        @position = [@position, time].max
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

      def with_lock
        with_lock_upstreams do
          @lock.with_write_lock { yield }
        end
      end

      def with_lock_upstreams
        locked = []
        @task.upstreams.each_key do |up_name|
          up_task = @engine.jobflow_operator[up_name]
          up_task.acquire_read_lock
          locked << up_task
        end

        yield
      ensure
        locked.each(&:release_read_lock)
      end
    end
  end
end

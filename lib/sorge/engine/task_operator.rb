module Sorge
  class Engine
    class TaskOperator
      Event = Struct.new(:task_name, :time)
      TaskResult = Struct.new(:successed?, :state, :emitted)
      TriggerContext = Struct.new(:state, :jobflow_status)

      def initialize(engine, task_name)
        @engine = engine
        @task = Sorge.tasks[task_name]

        @state = {}
        @trigger_state = {}
        @pending = PaneSet.new
        @running = [] # Array<Pane>
        @finished = []
        @position = Time.at(0)

        @worker = AsyncWorker.new(@engine)
        @mutex = Mutex.new
      end

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

          @running.each { @worker.post { perform } }
        end
      end

      def flush
        @mutex.synchronize do
          ps = @pending.panes
          @pending = PaneSet[]
          @running += ps
          ps.each { @worker.post { perform } }

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
        ready = ns_collect_ready(jobflow_status)
        return if ready.empty?

        @running += ready.to_a
        ready.each { @worker.post { perform } }
      end

      def ns_append_events(events)
        events.each do |event|
          time = @task.time_trunc.call(event.time)
          @pending = @pending.add(time, event.task_name)
        end
      end

      def ns_collect_ready(jobflow_status)
        context = TriggerContext[@trigger_state.dup, jobflow_status]
        ready, pending = @task.trigger.call(@pending.panes, context)
        @pending = PaneSet[*pending]
        @trigger_state = context.state
        ready
      end

      def perform
        pane = @mutex.synchronize { @running.first }

        result = execute(pane)

        @mutex.synchronize { ns_update_status(result) }
      end

      def execute(pane)
        context = DSL::TaskContext[@engine.application, pane.time, @state.dup]
        task_instance = @task.new(context)
        result = task_instance.invoke
        TaskResult[result, context.state, task_instance.emitted]
      end

      def ns_update_status(result)
        @state = result.state
        pane, *@running = @running

        return unless result.successed?

        @finished += result.emitted.empty? ? [pane.time] : result.emitted
        @position = [@position, pane.time].max
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

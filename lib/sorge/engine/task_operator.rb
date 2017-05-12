module Sorge
  class Engine
    class TaskOperator
      Event = Struct.new(:task_name, :time)
      TaskResult = Struct.new(:successed?, :state, :emitted)

      def initialize(engine, task_name)
        @engine = engine
        @task = Sorge.tasks[task_name]

        @state = {}
        @trigger_state = {}
        @pending = PaneSet.new
        @running = [] # Array<Pane>
        @finished = []
        @position = Time.at(0)

        @mutex = Mutex.new
        @stop = false
        @stopped = Concurrent::Event.new
      end

      def complete?
        @mutex.synchronize do
          @stop || [@pending, @running, @finished].all?(&:empty?)
        end
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

          @engine.worker.post { perform } unless @running.empty?
        end
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

      def ns_enqueue(events, jobflow_status)
        raise AlreadyStopped if @stop

        ns_append_events(events)
        ready = ns_collect_ready(jobflow_status)
        return if ready.empty?

        @running += ready.to_a
        @engine.worker.post { perform } if @running.length == ready.length
      end

      def ns_append_events(events)
        events.each do |event|
          time = @task.time_trunc.call(event.time)
          @pending = @pending.add(time, event.task_name)
        end
      end

      def ns_collect_ready(jobflow_status)
        ready, pending = @task.trigger.call(@pending.panes, jobflow_status)
        @pending = PaneSet[*pending]
        @trigger_state = @task.trigger.dump_state
        ready
      end

      def perform
        return @stopped.set if @stop

        pane = @mutex.synchronize { @running.first }
        return if pane.nil?

        result = execute(pane)

        @mutex.synchronize do
          ns_update_status(result)
          @engine.worker.post { perform } unless @running.empty?
        end
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

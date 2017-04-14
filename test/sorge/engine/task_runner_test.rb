require 'test_helper'

module Sorge
  class Engine
    class TaskRunnerTest < SorgeTest
      def context(time, state = {})
        TaskHandler::Context[time, state]
      end

      def task_runner
        app.engine.task_runner
      end

      def event_queue
        app.engine.event_queue
      end

      def test_post
        spy = []
        event = Concurrent::Event.new
        run_stub = lambda do |*args|
          spy << args
          event.set
        end
        job = tasks['t1'].new(context(0, {}))

        task_runner.stub(:run, run_stub) do
          task_runner.post(job)
          event.wait(1)
        end

        assert_equal job, spy[0][1]
      end

      def test_run
        job = tasks['t1'].new(context(0, {}))

        spy = []
        event_queue.stub(:submit, ->(*args) { spy << args }) do
          task_runner.send(:run, 'job_id', job)
        end

        assert_equal [
          [:successed, job_id: 'job_id', name: 't1', time: 0, state: {}]
        ], spy
        assert_equal [spy('t1')], SorgeTest.spy
      end

      def test_run_failure
        job = tasks['test_failure:t2'].new(context(0, {}))

        spy = []
        event_queue.stub(:submit, ->(*args) { spy << args }) do
          task_runner.send(:run, 'job_id', job)
        end

        assert_equal [spy('test_failure:t2')], SorgeTest.spy
        assert_equal [
          [:failed, job_id: 'job_id', name: 'test_failure:t2', time: 0, state: {}]
        ], spy
      end

      def test_hook
        job = app.dsl.task_manager['test_hook:t1'].new(context(0, {}))
        job.invoke
        assert_equal [:before, :run, :successed_in_mixin, :successed, :after],
                     SorgeTest.spy.map(&:name)
      end

      def test_hook2
        job = app.dsl.task_manager['test_hook:t2'].new(context(0, {}))
        job.invoke
        assert_equal [:before, :failed, :after], SorgeTest.spy.map(&:name)

        e = SorgeTest.spy.find { |s| s.name == :failed }.params[:error]
        assert_equal 'test', e.message
      end
    end
  end
end

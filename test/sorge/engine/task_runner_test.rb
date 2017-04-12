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
        task = tasks['t1']
        ctx = context(0, {})

        task_runner.stub(:run, run_stub) do
          task_runner.post(task, ctx)
          event.wait(1)
        end

        assert_equal [[task, ctx]], spy
      end

      def test_run
        task = tasks['t1']
        ctx = context(0, {})

        spy = []
        event_queue.stub(:submit, ->(*args) { spy << args }) do
          task_runner.send(:run, task, ctx)
        end

        assert_equal [[:complete, name: 't1', time: 0, state: {}]], spy
        assert_equal [SorgeTest::Spy['t1', {}]], SorgeTest.spy
      end

      def test_run_failure
        task = tasks['test_failure:t2']
        ctx = context(0, {})

        spy = []
        event_queue.stub(:submit, ->(*args) { spy << args }) do
          task_runner.send(:run, task, ctx)
        end

        assert_equal [SorgeTest::Spy['test_failure:t2', {}]], SorgeTest.spy
        assert_equal [], spy
      end
    end
  end
end
require 'test_helper'

module Sorge
  class Engine
    class TaskOperatorTest < SorgeTest
      def make_task_operator(task_name)
        TaskOperator.new(app.engine, task_name)
      end

      def test_post
        task_operator = make_task_operator('t1')

        status, = task_operator.post(10)
        status, = task_operator.post(11)
        status, = task_operator.post(12)
        assert_kind_of Hash, status.state
        assert_kind_of Array, status.queue

        finished_all = []
        loop do
          status, finished = task_operator.update
          finished_all += finished
          break if status.queue.empty?
          sleep 0.1
        end

        assert_equal [10, 11, 12], finished_all
        assert_equal %w(t1 t1 t1), SorgeTest.spy.map(&:name)
      end

      def test_update
        task_operator = make_task_operator('t2')

        status, f1 = task_operator.update('t1' => [10])
        status, f2 = task_operator.update('t1' => [11], 'dummy' => [0])
        status, f3 = task_operator.update('t1' => [12])
        assert_kind_of Hash, status.state
        assert_kind_of Array, status.queue

        finished_all = f1 + f2 + f3
        loop do
          status, finished = task_operator.update
          finished_all += finished
          break if status.queue.empty?
          sleep 0.1
        end

        assert_equal [10, 11, 12], finished_all
        assert_equal %w(t2 t2 t2), SorgeTest.spy.map(&:name)
      end

      def test_trigger
        task_operator = make_task_operator('test_trigger:t6')
        t0 = Time.new(2000, 1, 1, 12, 34, 0).to_i
        t1 = Time.new(2000, 1, 1, 12, 34, 56).to_i

        task_operator.post(t1)
        sleep 0.1
        status, = task_operator.update
        assert_equal [t0], status.queue

        task_operator.post(t1 + 1)
        sleep 0.1
        status, finished = task_operator.update
        assert_equal [t0], status.queue, 'time is truncated'
        assert_empty finished, 'no tasks run'

        task_operator.post(t1 - 60)
        sleep 0.1
        status, finished = task_operator.update
        assert_equal [t0, t0 - 60], status.queue
        assert_empty finished, 'no tasks run'

        task_operator.post(t1 + 3600)
        sleep 0.1
        status, finished = task_operator.update
        assert_equal [t0 + 3600], status.queue
        assert_equal [t0, t0 - 60], finished
      end

      def test_resume
        task_operator = make_task_operator('t1')

        task_operator.resume([0, 1], foo: 0)
        sleep 0.1
        status, finished = task_operator.update
        assert_equal [0, 1], finished
        assert_equal({ foo: 0 }, status.state)
      end

      def test_shutdown
        task_operator = make_task_operator('t1')

        task_operator.post(10)
        task_operator.shutdown
        assert_raises Sorge::AlreadyStopped do
          task_operator.post(11)
        end
        task_operator.wait_for_termination
      end
    end
  end
end

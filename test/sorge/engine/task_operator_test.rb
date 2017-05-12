require 'test_helper'

module Sorge
  class Engine
    class TaskOperatorTest < SorgeTest
      def make_task_operator(task_name)
        TaskOperator.new(app.engine, task_name)
      end

      def make_jobflow_status(finished = {})
        Hash.new do |hash, key|
          hash[key] = TaskStatus.new
          hash[key].finished = finished.fetch(key, [])
          hash[key].freeze!
        end
      end
      alias ctx make_jobflow_status

      def test_post
        task_operator = make_task_operator('t1')

        finished_all = []
        finished_all += task_operator.post(10, ctx).finished
        finished_all += task_operator.post(11, ctx).finished
        finished_all += task_operator.post(12, ctx).finished

        loop do
          finished_all += task_operator.update(ctx).finished
          break if finished_all.length == 3
          sleep 0.1
        end

        assert_equal [10, 11, 12], finished_all
        assert_equal %w(t1 t1 t1), SorgeTest.spy.map(&:name)
      end

      def test_update
        task_operator = make_task_operator('t2')

        finished_all = []
        finished_all += task_operator.update(ctx('t1' => [10])).finished
        finished_all += task_operator.update(ctx('t1' => [11], 'dummy' => [0])).finished
        finished_all += task_operator.update(ctx('t1' => [12])).finished

        loop do
          finished_all += task_operator.update(ctx).finished
          break if finished_all.length == 3
          sleep 0.1
        end

        assert_equal [10, 11, 12], finished_all
        assert_equal %w(t2 t2 t2), SorgeTest.spy.map(&:name)
      end

      def test_trigger
        task_operator = make_task_operator('test_trigger:t6')
        t0 = Time.new(2000, 1, 1, 12, 34, 0).to_i
        t1 = Time.new(2000, 1, 1, 12, 34, 56).to_i

        task_operator.post(t1, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0], status.pending.times
        assert_equal 0, status.position

        task_operator.post(t1 + 1, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0], status.pending.times, 'time is truncated'
        assert_empty status.finished, 'no tasks run'
        assert_equal 0, status.position

        task_operator.post(t1 - 60, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0, t0 - 60], status.pending.times
        assert_empty status.finished, 'no tasks run'
        assert_equal 0, status.position

        task_operator.post(t1 + 3600, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0 + 3600], status.pending.times
        assert_equal [t0, t0 - 60], status.finished
        assert_equal t0, status.position
      end

      def test_shutdown
        task_operator = make_task_operator('t1')

        task_operator.post(10, ctx)
        task_operator.shutdown
        assert_raises Sorge::AlreadyStopped do
          task_operator.post(11, ctx)
        end
        task_operator.wait_for_termination
      end
    end
  end
end

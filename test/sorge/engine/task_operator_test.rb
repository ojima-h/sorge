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
        finished_all += task_operator.post(now + 10, ctx).finished
        finished_all += task_operator.post(now + 11, ctx).finished
        finished_all += task_operator.post(now + 12, ctx).finished

        loop do
          finished_all += task_operator.update(ctx).finished
          break if finished_all.length == 3
          sleep 0.1
        end

        assert_equal [now + 10, now + 11, now + 12], finished_all
        assert_equal %w(t1 t1 t1), SorgeTest.spy.map(&:name)
      end

      def test_update
        task_operator = make_task_operator('t2')

        finished_all = []
        finished_all += task_operator.update(ctx('t1' => [now + 10])).finished
        finished_all += task_operator.update(ctx('t1' => [now + 11], 'dummy' => [0])).finished
        finished_all += task_operator.update(ctx('t1' => [now + 12])).finished

        loop do
          finished_all += task_operator.update(ctx).finished
          break if finished_all.length == 3
          sleep 0.1
        end

        assert_equal [now + 10, now + 11, now + 12], finished_all
        assert_equal %w(t2 t2 t2), SorgeTest.spy.map(&:name)
      end

      def test_trigger
        task_operator = make_task_operator('test_trigger:t6')
        t0 = Time.new(2000, 1, 1, 12, 34, 0)
        t1 = Time.new(2000, 1, 1, 12, 34, 56)

        task_operator.post(t1, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0], status.pending.times
        assert_equal({ latest: t0 }, status.trigger_state)
        assert_equal Time.at(0), status.position

        task_operator.post(t1 + 1, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0], status.pending.times, 'time is truncated'
        assert_empty status.finished, 'no tasks run'
        assert_equal({ latest: t0 }, status.trigger_state)
        assert_equal Time.at(0), status.position

        task_operator.post(t1 - 60, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0, t0 - 60], status.pending.times
        assert_empty status.finished, 'no tasks run'
        assert_equal({ latest: t0 }, status.trigger_state)
        assert_equal Time.at(0), status.position

        task_operator.post(t1 + 3600, ctx)
        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0 + 3600], status.pending.times
        assert_equal t0 - 60, status.running.time
        assert_equal [t0], status.finished
        assert_equal({ latest: t0 + 3600 }, status.trigger_state)
        assert_equal t0, status.position

        sleep 0.1
        status = task_operator.update(ctx)
        assert_equal [t0 + 3600], status.pending.times
        assert_nil status.running
        assert_equal [t0 - 60], status.finished
        assert_equal({ latest: t0 + 3600 }, status.trigger_state)
        assert_equal t0, status.position
      end

      def test_stop
        task_operator = make_task_operator('t1')

        task_operator.stop
        assert_raises Sorge::AlreadyStopped do
          task_operator.post(now, ctx)
        end
        task_operator.wait_stop
      end
    end
  end
end

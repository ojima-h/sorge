require 'test_helper'

module Sorge
  class DSL
    class TriggerTest < SorgeTest
      Pane = Engine::Pane
      TriggerContext = Engine::TaskOperator::TriggerContext

      def pane(time)
        Pane[time, 'foo']
      end

      def context(state = {})
        TriggerContext[state, {}]
      end
      alias ctx context

      def test_default
        trigger = Trigger.default
        panes = Array(10) { |i| pane(now + i) }
        ready, = trigger.call(panes, {})
        assert_equal panes, ready
      end

      def test_periodic
        trigger = Trigger::Periodic.new(nil, 0.2)
        panes = Array(10) { |i| pane(now + i) }

        count = 0
        5.times do
          ready, = trigger.call(panes, ctx)
          count += 1 unless ready.empty?
          sleep 0.1
        end

        assert 2, count
      end

      def test_lag
        trigger = Trigger::Lag.new(nil, 1)
        ctx = context

        ps = ->(i) { pane(now + i) }
        ready, pending = trigger.call([ps[8], ps[9], ps[10]], ctx)
        assert_equal [ps[8], ps[9]], ready
        assert_equal [ps[10]], pending.to_a

        ready, pending = trigger.call([ps[1], ps[2], ps[3]], ctx)
        assert_equal [ps[1], ps[2], ps[3]], ready
        assert_equal [], pending.to_a

        ready, pending = trigger.call([ps[9], ps[10], ps[11]], ctx)
        assert_equal [ps[9], ps[10]], ready
        assert_equal [ps[11]], pending.to_a

        assert_equal({ latest: now + 11 }, ctx.state)
      end

      def test_delay
        trigger = Trigger::Delay.new(nil, 3600)
        ps = ->(i) { pane(now + (i - 2) * 3600) }

        ready, pending = trigger.call([ps[0], ps[1], ps[2]], ctx)
        assert_equal [ps[0], ps[1]], ready
        assert_equal [ps[2]], pending
      end

      def test_align
        task = app.tasks['test_namespace:t3']
        trigger = Trigger::Align.new(task, lag: 1)

        pos = lambda do |i|
          Engine::TaskStatus.new.tap { |st| st.position = now + i }
        end
        ps = ->(i) { pane(now + i) }

        ctx = context
        ctx.jobflow_status = {
          'test_namespace:ns:t1' => pos[10],
          'test_namespace:ns:t2' => pos[12]
        }

        ready, pending = trigger.call(
          [ps[8], ps[9], ps[10], ps[11], ps[12], ps[13]],
          ctx
        )
        assert_equal [ps[8], ps[9]], ready
        assert_equal [ps[10], ps[11], ps[12], ps[13]], pending
      end

      def test_timeout
        trigger = Trigger::Lag.new(nil, 1, timeout: 0.1)
        ctx = context

        ps = [pane(now)]
        ready, pending = trigger.call(ps, ctx)
        assert_empty ready
        assert_equal ps, pending

        sleep 0.1

        ready, pending = trigger.call(ps, ctx)
        assert_equal ps, ready
        assert_empty pending
      end
    end
  end
end

require 'test_helper'

module Sorge
  class DSL
    class TriggerTest < SorgeTest
      Pane = Engine::Pane
      def pane(time)
        Pane[time, 'foo']
      end

      def test_default
        trigger = Trigger.default
        panes = Array(10) { |i| pane(Time.now.to_i + i) }
        ready, = trigger.call(panes, {})
        assert_equal panes, ready
      end

      def test_periodic
        trigger = Trigger::Periodic.new(nil, 0.2)
        panes = Array(10) { |i| pane(Time.now.to_i + i) }

        count = 0
        5.times do
          ready, = trigger.call(panes, {})
          count += 1 unless ready.empty?
          sleep 0.1
        end

        assert 2, count
      end

      def test_lag
        trigger = Trigger::Lag.new(nil, 1)

        ready, pending = trigger.call([pane(8), pane(9), pane(10)], {})
        assert_equal [8, 9], ready.map(&:time)
        assert_equal [10], pending.map(&:time)

        ready, pending = trigger.call([pane(1), pane(2), pane(3)], {})
        assert_equal [1, 2, 3], ready.map(&:time)
        assert_equal [], pending.map(&:time)

        ready, pending = trigger.call([pane(9), pane(10), pane(11)], {})
        assert_equal [9, 10], ready.map(&:time)
        assert_equal [11], pending.map(&:time)

        assert_equal({ latest: 11 }, trigger.state)
      end

      def test_delay
        trigger = Trigger::Delay.new(nil, 3600)
        now = Time.now.to_i
        t = ->(i) { pane(now + i * 3600) }

        ready, pending = trigger.call([t[-2], t[-1], t[0]], {})
        assert_equal [t[-2], t[-1]], ready
        assert_equal [t[0]], pending
      end
    end
  end
end

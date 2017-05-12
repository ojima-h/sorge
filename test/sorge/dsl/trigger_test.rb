require 'test_helper'

module Sorge
  class DSL
    class TriggerTest < SorgeTest
      PaneSet = Engine::PaneSet

      def pane_set(*times)
        PaneSet[*times.map { |time| [time, 'foo'] }]
      end

      def test_default
        trigger = Trigger.default
        times = Array(10) { |i| Time.now.to_i + i }
        ready, = trigger.call(pane_set(*times), {})
        assert_equal times, ready.times
      end

      def test_periodic
        trigger = Trigger::Periodic.new(nil, 0.2)
        times = Array(10) { |i| Time.now.to_i + i }

        count = 0
        5.times do
          ready, = trigger.call(pane_set(*times), {})
          count += 1 unless ready.empty?
          sleep 0.1
        end

        assert 2, count
      end

      def test_lag
        trigger = Trigger::Lag.new(nil, 1)

        ready, pending = trigger.call(pane_set(8, 9, 10), {})
        assert_equal [8, 9], ready.times
        assert_equal [10], pending.times

        ready, pending = trigger.call(pane_set(1, 2, 3), {})
        assert_equal [1, 2, 3], ready.times
        assert_equal [], pending.times

        ready, pending = trigger.call(pane_set(9, 10, 11), {})
        assert_equal [9, 10], ready.times
        assert_equal [11], pending.times

        assert_equal({ latest: 11 }, trigger.state)
      end

      def test_delay
        trigger = Trigger::Delay.new(nil, 3600)
        now = Time.now.to_i
        t = ->(i) { now + i * 3600 }

        ready, pending = trigger.call(pane_set(t[-2], t[-1], t[0]), {})
        assert_equal [t[-2], t[-1]], ready.times
        assert_equal [t[0]], pending.times
      end
    end
  end
end

require 'test_helper'

module Sorge
  class DSL
    class TriggerTest < SorgeTest
      def test_default
        trigger = Trigger.default
        times = Array(10) { |i| Time.now.to_i + i }
        ready, = trigger.call(times)
        assert_equal times, ready
      end

      def test_periodic
        trigger = Trigger::Periodic.new(0.2)
        times = Array(10) { |i| Time.now.to_i + i }

        count = 0
        5.times do
          ready, = trigger.call(times)
          count += 1 unless ready.empty?
          sleep 0.1
        end

        assert 2, count
      end

      def test_lag
        trigger = Trigger::Lag.new(1)

        ready, pending = trigger.call([8, 9, 10])
        assert_equal [8, 9], ready
        assert_equal [10], pending

        ready, pending = trigger.call([1, 2, 3])
        assert_equal [1, 2, 3], ready
        assert_equal [], pending

        ready, pending = trigger.call([9, 10, 11])
        assert_equal [9, 10], ready
        assert_equal [11], pending
      end

      def test_delay
        trigger = Trigger::Delay.new(3600)
        now = Time.now.to_i
        t = ->(i) { now + i * 3600 }

        ready, pending = trigger.call([t[-2], t[-1], t[0]])
        assert_equal [t[-2], t[-1]], ready
        assert_equal [t[0]], pending
      end
    end
  end
end

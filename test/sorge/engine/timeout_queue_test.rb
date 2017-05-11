require 'test_helper'

module Sorge
  class Engine
    class TimeoutQueueTest < SorgeTest
      def test_queue
        q = TimeoutQueue.new

        ts = Array.new(2) { Thread.new { q.shift } }

        q << 1 << 2

        assert_equal [1, 2], ts.map(&:value).sort
        assert_nil q.shift(0)

        t = Thread.new { q.shift }
        t.join(0.1)
        assert_equal 'sleep', t.status
      end

      def test_close
        q = TimeoutQueue.new

        q << 1 << 2
        q.close

        assert_raises TimeoutQueue::ClosedQueueError do
          q << 1
        end

        assert_equal 1, q.shift
        assert_equal 2, q.shift
        assert_raises TimeoutQueue::ClosedQueueError do
          q.shift
        end
      end
    end
  end
end

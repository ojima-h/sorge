require 'test_helper'

module Sorge
  class Model
    class EventQueueTest < SorgeTest
      def queue
        app.model.event_queue
      end

      def test_ok
        queue.post('foo', bar: 1)
        queue.post('foo', bar: 2)
        queue.post('foo', bar: 3)

        msg = queue.get
        assert_equal 'foo', msg.name
        assert_equal({ bar: 1 }, msg.data)

        msg = queue.get
        assert_equal({ bar: 2 }, msg.data)
      end
    end
  end
end

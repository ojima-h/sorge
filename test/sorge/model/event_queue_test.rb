require 'test_helper'

module Sorge
  class Model
    class EventQueueTest < SorgeTest
      def queue
        app.model.event_queue
      end

      def test_ok
        queue.post('foo', bar: 1)

        msg = queue.get

        assert_equal 'foo', msg.name
        assert_equal({ bar: 1 }, msg.data)
      end
    end
  end
end

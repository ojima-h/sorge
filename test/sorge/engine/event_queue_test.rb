require 'test_helper'

module Sorge
  class Engine
    class EventQueueTest < SorgeTest
      def event_queue
        app.engine.event_queue
      end

      def test_submit
        spy = []
        event = Concurrent::Event.new
        stub_notify = lambda do |*args|
          spy << args
          event.set
        end

        event_queue.stub(:submit, stub_notify) do
          event_queue.submit(:notify, name: 'foo', time: 1, dest: 'bar')
        end

        event.wait(1)
        assert_equal [[:notify, name: 'foo', time: 1, dest: 'bar']], spy
      end
    end
  end
end

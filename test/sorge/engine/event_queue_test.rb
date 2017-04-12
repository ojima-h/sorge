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

      def test_job_flow
        event_queue.submit(:run, name: 'test_failure:t1', time: Time.now.to_i)

        10.times do
          break if SorgeTest.spy.length == 4
          sleep 0.1
        end

        assert_equal 4, SorgeTest.spy.length
        assert_includes SorgeTest.spy, spy('test_failure:t1')
        assert_includes SorgeTest.spy, spy('test_failure:t2')
        assert_includes SorgeTest.spy, spy('test_failure:t3')
        assert_includes SorgeTest.spy, spy('test_failure:t5')
      end
    end
  end
end

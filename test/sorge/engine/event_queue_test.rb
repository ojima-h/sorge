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

        ns = SorgeTest.spy.map(&:name)
        assert_equal 4, ns.length
        assert_equal [
          'test_failure:t1',
          'test_failure:t2',
          'test_failure:t3',
          'test_failure:t5'
        ], ns.sort
      end
    end
  end
end

require 'test_helper'

module Sorge
  class Engine
    class AgentTest < SorgeTest
      def factory(name)
        Agent.new(app.engine, tasks[name])
      end

      def test_execute
        agent = factory('t2')

        agent.execute(0)
        assert_equal [SorgeTest::Spy['t2', {}]], SorgeTest.spy
      end

      def test_submit
        agent = factory('t2')
        latch = Concurrent::CountDownLatch.new(2)
        spy = []
        stub = lambda do |i:|
          latch.count_down
          spy << i
        end
        agent.stub(:proc_upstream, stub) do
          agent.submit(:upstream, i: 0)
          agent.submit(:upstream, i: 1)
          latch.wait(1)
        end
        assert_equal [0, 1], spy
      end

      def test_upstream
        agent = factory('t2')
        tm = Time.now.to_i

        spy = []
        agent.stub(:submit, ->(*args) { spy << args }) do
          agent.state.session do
            agent.proc_upstream(name: 't1', time: tm)
            agent.proc_upstream(name: 't1', time: tm + 1)
            agent.proc_upstream(name: 't1', time: tm + 2)
          end
        end

        assert_equal [
          [:run, time: tm],
          [:run, time: tm + 1]
        ], spy
      end
    end
  end
end

require 'test_helper'

module Sorge
  class Engine
    class AgentTest < SorgeTest
      def factory(name)
        Agent.new(app.engine, tasks[name])
      end

      def spy(*args, &block)
        (@spy ||= []) << [*args, block]
      end

      def test_execute
        agent = factory('t2')

        agent.execute
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
        return
        agent = factory('t2')
        agent.stub(:execute, method(:spy)) do
          tm = Time.now.to_i

          agent.submit(:upstream, name: 't1', time: tm)
          agent.submit(:upstream, name: 't1', time: tm + 1)
          agent.submit(:upstream, name: 't1', time: tm + 2)

          assert_equal [
            [[:time, tm]],
            [[:time, tm + 1]],
            [[:time, tm + 2]]
          ], @spy
        end
      end
    end
  end
end

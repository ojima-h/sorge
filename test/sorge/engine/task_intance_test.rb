require 'test_helper'

module Sorge
  class Engine
    class TaskInstanceTest < SorgeTest
      def test_params
        invoke('test_params:t1', i: 0).wait

        assert_includes SorgeTest.spy, Spy['test_params:t1', i: 0]
        assert_includes SorgeTest.spy, Spy['test_params:t2', i: 0]
        assert_includes SorgeTest.spy, Spy['test_params:t3', i: 1]
        assert_includes SorgeTest.spy, Spy['test_params:t4', i: 0, j: 1]
      end
    end
  end
end

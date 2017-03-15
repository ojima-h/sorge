require 'test_helper'

module Sorge
  class Engine
    class DriverTest < SorgeTest
      def test_invoke
        invoke('t1')
        assert_equal [['t1'], ['t2']], SorgeTest.spy
      end
    end
  end
end

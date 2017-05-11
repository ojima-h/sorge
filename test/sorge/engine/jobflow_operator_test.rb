require 'test_helper'

module Sorge
  class Engine
    class JobflowOperatorTest < SorgeTest
      def make_jobflow_operator
        JobflowOperator.new(app.engine)
      end

      def test_submit
        jobflow = make_jobflow_operator
        jobflow.submit('test_namespace:ns:t1', Time.now.to_i)
        jobflow.complete

        assert_equal [
          'test_namespace:ns:t1',
          'test_namespace:ns:t2',
          'test_namespace:t3', 'test_namespace:t3',
          'test_namespace:t4', 'test_namespace:t4', 'test_namespace:t4'
        ], SorgeTest.spy.map(&:name).sort
      end
    end
  end
end

require 'test_helper'

module Sorge
  class Engine
    class DriverTest < SorgeTest
      def test_invoke
        invoke('t1').wait
        assert_equal [['t1'], ['t2']], SorgeTest.spy
      end

      def test_invoke2
        invoke('test_namespace:ns:t1').wait
        assert_equal [['test_namespace:ns:t1'], ['test_namespace:ns:t2'],
                      ['test_namespace:t3'], ['test_namespace:t4']],
                     SorgeTest.spy
      end

      def test_failure
        batch = invoke('test_failure:t1').wait

        assert_includes SorgeTest.spy, ['test_failure:t1']
        assert_includes SorgeTest.spy, ['test_failure:t2']
        assert_includes SorgeTest.spy, ['test_failure:t3']
        assert_includes SorgeTest.spy, ['test_failure:t5']
        refute_includes SorgeTest.spy, ['test_failure:t4']
        refute_includes SorgeTest.spy, ['test_failure:t6']

        assert batch.jobs['test_failure:t2'].status.failed?
        assert batch.jobs['test_failure:t3'].status.successed?
        assert batch.jobs['test_failure:t4'].status.cancelled?
        assert batch.jobs['test_failure:t5'].status.successed?
        assert batch.jobs['test_failure:t6'].status.cancelled?
      end
    end
  end
end

require 'test_helper'

module Sorge
  class DSL
    class CoreWorkerTest < SorgeTest
      def test_default
        assert_equal :default, app.tasks['t1'].worker
        assert_equal :w1, app.tasks['test_worker:t1'].worker
        assert_equal :w1, app.tasks['test_worker:t2'].worker
      end
    end
  end
end

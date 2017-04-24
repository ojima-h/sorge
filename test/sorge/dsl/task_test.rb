require 'test_helper'

module Sorge
  class DSL
    class TaskTest < SorgeTest
      def test_ok
        assert_operator Task, :>, DSL.instance.task_manager[:t1]
      end

      def test_namespace
        t = DSL.instance.task_manager['test_namespace:t3']
        assert_equal 'test_namespace:t3', t.name
      end

      def test_upstream
        us = DSL.instance.task_manager[:t2].predecessors
        assert_equal ['t1'], us.keys

        us = DSL.instance.task_manager['test_namespace:t3'].predecessors
        assert_equal ['test_namespace:ns:t1', 'test_namespace:ns:t2'],
                     us.keys
      end

      def test_helper
        assert_equal :h1, DSL.instance.task_manager['test_namespace:ns:t1'].h1
      end
    end
  end
end

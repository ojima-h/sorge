require 'test_helper'

module Sorge
  class DSL
    class TaskTest < SorgeTest
      def test_ok
        assert_operator Task, :>, app.dsl.task_manager[:t1]
      end

      def test_namespace
        t = app.dsl.task_manager['test_namespace:t3']
        assert_equal 'test_namespace:t3', t.name
      end

      def test_upstream
        us = app.dsl.task_manager[:t2].predecessors
        assert_equal ['t1'], us.keys.map(&:name)

        us = app.dsl.task_manager['test_namespace:t3'].predecessors
        assert_equal ['test_namespace:ns:t1', 'test_namespace:ns:t2'],
                     us.keys.map(&:name)
      end

      def test_helper
        assert_equal :h1, app.dsl.task_manager['test_namespace:ns:t1'].h1
      end

      def test_call_action
        app.dsl.task_manager[:t1].new(nil).send(:call_action, :action)

        assert_equal [['t1']], SorgeTest.spy
      end
    end
  end
end

require 'test_helper'

module Sorge
  class DSL
    class TaskTest < SorgeTest
      def test_ok
        assert_operator Task, :>, app.tasks[:t1]
      end

      def test_namespace
        t = app.tasks['test_namespace:t3']
        assert_equal 'test_namespace:t3', t.name
      end

      def test_upstream
        us = app.tasks[:t2].upstreams
        assert_equal ['t1'], us.keys

        us = app.tasks['test_namespace:t3'].upstreams
        assert_equal ['test_namespace:ns:t1', 'test_namespace:ns:t2'],
                     us.keys
      end

      def test_helper
        assert_equal :h1, app.tasks['test_namespace:ns:t1'].h1
      end

      def test_hook
        job = app.tasks['test_hook:t1'].new(TaskContext[0])
        job.invoke
        assert_equal [:before, :run, :successed_in_mixin, :successed, :after],
                     SorgeTest.spy.map(&:name)
      end

      def test_hook2
        job = app.tasks['test_hook:t2'].new(TaskContext[0])
        job.invoke
        assert_equal [:before, :failed, :after], SorgeTest.spy.map(&:name)

        e = SorgeTest.spy.find { |s| s.name == :failed }.error
        assert_equal 'test', e.message
      end
    end
  end
end

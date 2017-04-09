require 'test_helper'

module Sorge
  class DSL
    class WindowTest < SorgeTest
      def factory(name)
        TaskAgent.new(app.engine, name)
      end

      def test_null
        window = tasks['test_window:t1'].window_handler
        assert_equal [0], window.update(nil, nil, 0)
        assert_equal [1], window.update(nil, nil, 1)
        assert_equal [2], window.update(nil, nil, 2)
      end

      def test_default
        state = {}
        window = tasks['test_window:t3'].window_handler

        t = Time.now.to_i / 3 * 3
        assert_equal [], window.update(state, 'test_window:t1', t)
        assert_equal [], window.update(state, 'test_window:t1', t + 1)
        assert_equal [], window.update(state, 'test_window:t1', t + 2)
        assert_equal [], window.update(state, 'test_window:t1', t + 3)
        assert_equal [], window.update(state, 'test_window:t2', t)
        assert_equal [], window.update(state, 'test_window:t2', t + 1)
        assert_equal [], window.update(state, 'test_window:t2', t + 2)
        assert_equal [t], window.update(state, 'test_window:t2', t + 3)
      end

      def test_daily_window
        state = {}
        window = tasks['test_window:t4'].window_handler

        t = Time.new(2000, 1, 1, 12).to_i
        assert_equal [], window.update(state, 'test_window:t1', t)
        assert_equal [], window.update(state, 'test_window:t1', t + 1)
        assert_equal [], window.update(state, 'test_window:t1', t + 2)
        d1 = Time.new(2000, 1, 1).to_i
        d2 = Time.new(2000, 1, 2).to_i
        assert_equal [d1], window.update(state, 'test_window:t1', d2)
      end

      def test_continuous_and_daily
        state = {}
        window = tasks['test_window:t5'].window_handler

        t = Time.new(2000, 1, 1, 12).to_i
        assert_equal [], window.update(state, 'test_window:t2', t)
        assert_equal [], window.update(state, 'test_window:t2', t + 1)
        assert_equal [], window.update(state, 'test_window:t2', t + 2)
        d = Time.new(2000, 1, 1).to_i
        assert_equal [d], window.update(state, 'test_window:t4', d)
      end
    end
  end
end

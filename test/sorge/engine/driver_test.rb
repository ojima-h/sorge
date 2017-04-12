require 'test_helper'

module Sorge
  class Engine
    class DriverTest < SorgeTest
      def test_invoke
        invoke('t1')
        assert_equal %w(t1 t2), SorgeTest.spy.map(&:name)
      end

      def test_invoke2
        invoke('test_namespace:ns:t1')
        assert_equal %w(test_namespace:ns:t1 test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name)
      end

      def test_failure
        invoke('test_failure:t1')

        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t1'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t2'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t3'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t5'
        refute_includes SorgeTest.spy.map(&:name), 'test_failure:t4'
        refute_includes SorgeTest.spy.map(&:name), 'test_failure:t6'
      end

      def test_fatal_error
        e = assert_raises Exception do
          app.engine.driver.run('test_failure:fatal', Time.now.to_i)
        end
        assert_equal 'test fatal', e.message
      end

      def test_unexpected_error
        assert_raises NameError do
          app.engine.driver.run('undefined_task', Time.now.to_i)
        end
      end
    end
  end
end

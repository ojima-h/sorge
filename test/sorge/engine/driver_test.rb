require 'test_helper'

module Sorge
  class Engine
    class DriverTest < SorgeTest
      def test_invoke
        invoke('t1').wait
        assert_equal %w(t1 t2), SorgeTest.spy.map(&:name)
      end

      def test_invoke2
        invoke('test_namespace:ns:t1').wait
        assert_equal %w(test_namespace:ns:t1 test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name)
      end

      def test_run
        app.engine.driver.run('test_namespace:ns:t1', Time.now.to_i)
        assert_equal %w(test_namespace:ns:t1 test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name)
      end

      def test_failure
        jobflow = invoke('test_failure:t1').wait

        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t1'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t2'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t3'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t5'
        refute_includes SorgeTest.spy.map(&:name), 'test_failure:t4'
        refute_includes SorgeTest.spy.map(&:name), 'test_failure:t6'

        assert jobflow.jobs['test_failure:t2'].status.failed?
        assert jobflow.jobs['test_failure:t3'].status.successed?
        assert jobflow.jobs['test_failure:t4'].status.cancelled?
        assert jobflow.jobs['test_failure:t5'].status.successed?
        assert jobflow.jobs['test_failure:t6'].status.cancelled?

        assert_equal 'test', jobflow.jobs['test_failure:t2'].error.message
      end

      def test_failure_while_setup
        jobflow = invoke('test_failure:t7').wait
        assert jobflow.jobs['test_failure:t7'].status.failed?
        assert_equal 'test', jobflow.jobs['test_failure:t7'].error.message
      end

      def test_jobflows
        jobflows = []
        SorgeTest.hook('test_namespace:t3') do |task|
          jobflows << task.context.engine.driver.jobflows.dup
        end
        j1 = invoke('test_namespace:ns:t1')
        j2 = invoke('test_namespace:ns:t1')
        j3 = invoke('test_namespace:ns:t1')
        [j1, j2, j3].each(&:wait)

        assert jobflows.any? { |jf| jf.include? j1.id }
        assert jobflows.any? { |jf| jf.include? j2.id }
        assert jobflows.any? { |jf| jf.include? j3.id }
        assert_empty app.engine.driver.jobflows
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

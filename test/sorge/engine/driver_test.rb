require 'test_helper'

module Sorge
  class Engine
    class DriverTest < SorgeTest
      def test_invoke
        invoke('t1')
        assert_equal %w(t1 t2), SorgeTest.spy.map(&:name).uniq
      end

      def test_invoke2
        invoke('test_namespace:ns:t1')
        assert_equal %w(test_namespace:ns:t1 test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name).uniq.sort
      end

      def test_failure
        invoke('test_failure:t1')

        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t1'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t2'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t3'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t5'
        refute_includes SorgeTest.spy.map(&:name), 'test_failure:t4'
        assert_includes SorgeTest.spy.map(&:name), 'test_failure:t6'
      end

      def test_fatal_error
        invoke('test_failure:fatal', now)
        assert app.engine.jobflow_operator.instance_eval { @killed.set? }
      end

      def test_unexpected_error
        assert_raises NameError do
          app.engine.driver.submit('undefined_task', now)
        end
      end

      def test_emit
        invoke('test_emit:t1', now)

        assert_equal [
          'test_emit:t1',
          'test_emit:t2'
        ], SorgeTest.spy.map(&:name).uniq
        assert_equal [
          now,
          Time.at(100),
          Time.at(200),
          Time.at(300)
        ], SorgeTest.spy.map(&:time).uniq
      end

      def test_restore
        data = {
          'test_namespace:ns:t2' => {
            run: [{ tm: now, es: [{ name: nil }] }]
          }
        }

        Tempfile.open('resume-test.yml') do |f|
          f.write(YAML.dump(data))
          f.close
          app.engine.driver.resume(f.path)
          app.engine.jobflow_operator.wait_complete
        end

        assert_equal %w(test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name).uniq
      end
    end
  end
end

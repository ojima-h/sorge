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
          invoke('test_failure:fatal', Time.now.to_i)
        end
        assert_equal 'test fatal', e.message
      end

      def test_unexpected_error
        assert_raises NameError do
          app.engine.driver.run('undefined_task', Time.now.to_i)
        end
      end

      def test_emit
        invoke('test_emit:t1', 0)

        assert_equal [
          'test_emit:t1',
          'test_emit:t2',
          'test_emit:t2',
          'test_emit:t2'
        ], SorgeTest.spy.map(&:name)
        assert_equal [
          0,
          100,
          200,
          300
        ], SorgeTest.spy.map { |x| x.time.to_i }
      end

      def test_restore
        app.remote_mode = true

        savepoint = {
          queue: [
            [:successed, job_id: '1', name: 'test_namespace:ns:t1', time: 100, state: {}],
            [:stop],
            [:run, name: 'test_namespace:t3', time: 100],
            [:savepoint]
          ],
          running: {
            '1' => { name: 'test_namespace:ns:t1', time: 100, state: {} },
            '2' => { name: 'test_namespace:ns:t2', time: 100, state: {} }
          },
          states: {
            'foo' => { bar: 1 }
          }
        }

        event_queue_spy = []
        event_queue_stub = ->(*args) { event_queue_spy << args }

        task_runner_spy = []
        task_runner_stub = ->(job) { task_runner_spy << job }

        Tempfile.open('resume-test.yml') do |f|
          f.write(YAML.dump(savepoint))
          f.close

          app.engine.event_queue.stub(:submit, event_queue_stub) do
            app.engine.task_runner.stub(:post, task_runner_stub) do
              app.engine.driver.resume(f.path)
            end
          end
        end

        assert_equal [
          [:successed, job_id: '1', name: 'test_namespace:ns:t1', time: 100, state: {}],
          [:run, name: 'test_namespace:t3', time: 100]
        ], event_queue_spy

        assert_equal ['test_namespace:ns:t2'], task_runner_spy.map(&:name)
      end

      def test_resume
        app.remote_mode = true

        savepoint = {
          queue: [[:run, name: 'test_namespace:ns:t1', time: 100]],
          running: [],
          states: {}
        }

        Tempfile.open('resume-test.yml') do |f|
          f.write(YAML.dump(savepoint))
          f.close

          app.engine.driver.resume(f.path)
          app.shutdown
        end

        assert_equal %w(test_namespace:ns:t1 test_namespace:ns:t2
                        test_namespace:t3 test_namespace:t4),
                     SorgeTest.spy.map(&:name)
      end
    end
  end
end

require 'test_helper'

module Sorge
  class Engine
    class JobflowOperatorTest < SorgeTest
      def make_jobflow_operator
        JobflowOperator.new(app.engine)
      end

      def test_submit
        jobflow = make_jobflow_operator
        jobflow.submit('test_namespace:ns:t1', now)
        jobflow.wait_complete

        assert_equal [
          'test_namespace:ns:t1',
          'test_namespace:ns:t2',
          'test_namespace:t3', 'test_namespace:t3',
          'test_namespace:t4', 'test_namespace:t4', 'test_namespace:t4'
        ], SorgeTest.spy.map(&:name).sort
      end

      def test_kill
        jobflow = make_jobflow_operator
        t = Thread.new { jobflow.invoke('test_namespace:ns:t1', now) }
        jobflow.kill
        begin
          t.join(0.1)
        rescue
          nil
        end
        assert t.stop?
      end

      def test_resume
        jobflow = make_jobflow_operator
        data = {
          'test_namespace:ns:t1' => {
            run: [{ tm: now, es: [{ name: nil }] }]
          }
        }

        jobflow.resume(data)
        jobflow.wait_complete

        assert_equal [
          'test_namespace:ns:t1',
          'test_namespace:ns:t2',
          'test_namespace:t3', 'test_namespace:t3',
          'test_namespace:t4', 'test_namespace:t4', 'test_namespace:t4'
        ], SorgeTest.spy.map(&:name).sort
      end
    end
  end
end

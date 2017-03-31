require 'test_helper'

module Sorge
  class Engine
    class SavepointTest < SorgeTest
      def test_success
        j = invoke('test_namespace:ns:t1').wait

        assert j.complete?

        refute File.file?(app.engine.savepoint.jobflow_file_path(j.id))
      end

      def test_failed
        j = invoke('test_failure:t1', i: 1).wait

        assert j.failed?

        assert File.file?(app.engine.savepoint.jobflow_file_path(j.id))
        body = app.engine.savepoint.get_jobflow(j.id)
        assert_equal [{ 'name' => 'test_failure:t2', 'params' => {} }], body
      end

      def test_kill
        e = Concurrent::Event.new
        SorgeTest.hook('test_params:t3') do
          e.set
          sleep
        end
        j = invoke('test_params:t1', i: 1)
        e.wait
        sleep 0.01 until j.jobs['test_params:t2'].status.complete?
        app.engine.kill

        assert j.failed?

        assert File.file?(app.engine.savepoint.jobflow_file_path(j.id))
        body = app.engine.savepoint.get_jobflow(j.id)
        assert_equal [{ 'name' => 'test_params:t3', 'params' => { i: 2 } }],
                     body
      end
    end
  end
end

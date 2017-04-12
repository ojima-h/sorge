require 'test_helper'

module Sorge
  class Engine
    class SavepointTest < SorgeTest
      def savepoint
        app.engine.savepoint
      end

      def test_dump
        stub_q = [[:foo, param: 1], [:foo, param: 2]]
        stub_run = { 'xxx' => { name: 'bar', time: 100 } }
        stub_st = { 'bar' => { baz: 1 } }
        app.engine.event_queue.stub(:queue, stub_q) do
          app.engine.task_runner.stub(:running, stub_run) do
            app.engine.stub(:task_states, stub_st) do
              savepoint.dump

              assert File.file?(savepoint.latest)
              assert_equal <<-YAML, File.read(savepoint.latest)
---
:queue:
- - :foo
  - :param: 1
- - :foo
  - :param: 2
:running:
  xxx:
    :name: bar
    :time: 100
:states:
  bar:
    :baz: 1
              YAML
            end
          end
        end
      end

      def test_clean
        FileUtils.makedirs(app.config.get('savepoint.path'))
        junk = File.join(app.config.get('savepoint.path'), 'junk')
        File.write(junk, '')

        savepoint.dump
        path = savepoint.latest
        assert File.file?(path)
        assert File.file?(junk)

        savepoint.dump
        refute File.file?(path)
        assert File.file?(junk)
      end

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

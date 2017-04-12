require 'test_helper'

module Sorge
  class Engine
    class SavepointTest < SorgeTest
      def savepoint
        app.engine.savepoint
      end

      def test_update
        stub_q = [[:foo, param: 1], [:foo, param: 2]]
        stub_p = { 'bar' => [{ name: 'bar', time: 100 }] }
        stub_st = { 'bar' => { baz: 1 } }
        app.engine.event_queue.stub(:queue, stub_q) do
          app.engine.task_runner.stub(:running, stub_p) do
            app.engine.stub(:task_states, stub_st) do
              savepoint.update

              assert File.file?(savepoint.latest)
              assert_equal <<-YAML, File.read(savepoint.latest)
---
:queue:
- - :foo
  - :param: 1
- - :foo
  - :param: 2
:running:
  bar:
  - :name: bar
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

        savepoint.update
        path = savepoint.latest
        assert File.file?(path)
        assert File.file?(junk)

        savepoint.update
        refute File.file?(path)
        assert File.file?(junk)
      end
    end
  end
end

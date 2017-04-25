require 'test_helper'

module Sorge
  class Engine
    class SavepointTest < SorgeTest
      def savepoint
        app.engine.savepoint
      end

      def test_update
        app.remote_mode = true
        stub_data = {
          queue: [
            [:foo, param: 1],
            [:foo, param: 2]
          ],
          running: {
            'job_id' => { name: 'bar', time: 100 }
          },
          states: {
            'bar' => { baz: 1 }
          }
        }
        app.engine.savepoint.stub(:data, stub_data) do
          savepoint.update

          assert File.file?(savepoint.latest)
          assert_equal stub_data, YAML.load_file(savepoint.latest)
        end
      end

      def test_clean
        app.remote_mode = true
        FileUtils.makedirs(app.config.savepoint_path)
        junk = File.join(app.config.savepoint_path, 'junk')
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

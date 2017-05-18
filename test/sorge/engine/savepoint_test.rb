require 'test_helper'

module Sorge
  class Engine
    class SavepointTest < SorgeTest
      def savepoint
        app.engine.savepoint
      end

      def test_update
        data = { foo: 'bar' }
        savepoint.save(data)
        assert File.file?(savepoint.latest)
        assert_equal data, savepoint.read('latest')
      end

      def test_dryrun
        app.stub(:dryrun?, true) do
          savepoint.save(foo: 'bar')
          assert_nil savepoint.latest
        end
      end

      def test_disable_savepoint
        app.stub(:savepoint?, false) do
          savepoint.save(foo: 'bar')
          assert_nil savepoint.latest
        end
      end

      def test_clean
        FileUtils.makedirs(app.config.savepoint_path)
        junk = File.join(app.config.savepoint_path, 'junk')
        File.write(junk, '')

        savepoint.save(foo: 'bar')
        path = savepoint.latest
        assert File.file?(path)
        assert File.file?(junk)

        savepoint.save(foo: 'bar')
        refute File.file?(path)
        assert File.file?(junk)
      end
    end
  end
end

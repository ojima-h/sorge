require 'test_helper'

module Sorge
  class ConfigLoaderTest < SorgeTest
    def create_tmp_yaml(data)
      Tempfile.open('config-test.yml') do |f|
        f.puts YAML.dump(data)
        f.close
        yield f.path
      end
    end

    def test_config
      data = {
        'a' => 1,
        'b' => { 'foo' => 'bar' }
      }
      create_tmp_yaml(data) do |path|
        config = ConfigLoader.new(config_file: path, sorgefile: 'dummy').load

        assert_equal 1, config.a
        assert_equal({'foo' => 'bar'}, config.b)

        assert_equal 'dummy', config.sorgefile
      end
    end

    def test_default
      create_tmp_yaml('process_dir' => 'foo') do |path|
        config = ConfigLoader.new(config_file: path).load

        assert_equal 'foo/savepoints', config.savepoint_path
      end
    end

    def test_environment
      create_tmp_yaml({}) do |path|
        config = ConfigLoader.new(config_file: path, environment: 'foo').load

        assert_equal 'var/sorge/foo/savepoints', config.savepoint_path
      end
    end
  end
end

require 'test_helper'

module Sorge
  class ConfigTest < SorgeTest
    def create_tmp_yaml(data)
      Tempfile.open('config-test.yml') do |f|
        f.puts YAML.dump(data)
        f.close
        yield f.path
      end
    end

    def test_config
      data = {
        'a' => { 'b1' => { 'c' => 1 }, 'b2' => { 'c' => 2 } }
      }
      create_tmp_yaml(data) do |path|
        config = Config.new(config_file: path, sorgefile: 'dummy')

        assert_equal 1, config.get('a.b1.c')
        assert config.include?('a.b1.c')
        assert_equal({ c: 2 }, config.get('a.b2'))

        assert_nil config.get('a.b0.c')
        refute config.include?('a.b0.c')

        config.set('a.b3.c', 3)
        assert_equal 3, config.get('a.b3.c')

        config.set('a.b1.c.d', 2)
        assert_equal({ d: 2 }, config.get('a.b1.c'))

        config.set_default('a.b2.c.d', 3)
        assert_equal 2, config.get('a.b2.c')

        config.set_default('a.b2.d', 3)
        assert_equal 3, config.get('a.b2.d')

        assert_equal 'dummy', config.get('core.sorgefile')
      end
    end
  end
end

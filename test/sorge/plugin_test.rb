require 'test_helper'

module Sorge
  class PluginTest < SorgeTest
    def test_script
      invoke('test_plugin:t1')
    end
  end
end

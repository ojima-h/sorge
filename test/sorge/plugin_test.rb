require 'test_helper'

module Sorge
  class PluginTest < SorgeTest
    class DummyPlugin < Plugin::Base
      register :dummy

      def setup
        @number = 1
      end
      attr_reader :number
    end

    def test_plugin
      assert_kind_of DummyPlugin, app.plugins.dummy
      assert_equal 1, app.plugins.dummy.number
      assert_equal app, app.plugins.dummy.app
    end

    def test_command
      invoke('test_plugin:t1')
    end
  end
end

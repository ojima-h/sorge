require 'test_helper'

module Sorge
  class DSL
    class CoreTest < SorgeTest
      def test_hook_inheritance
        t = app.tasks['test_supermixin:t4']
        hooks = []
        t.each_hook(:before) { |h| hooks << h }
        assert_equal 4, hooks.length
      end
    end
  end
end

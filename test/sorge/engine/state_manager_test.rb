require 'test_helper'

module Sorge
  class Engine
    class StateManagerTest < SorgeTest
      def state_manager
        app.engine.state_manager
      end

      def test_fetch
        assert_equal({}, state_manager.fetch(:x))
      end

      def test_update
        state_manager.update(:x, foo: 0)
        assert_equal({ foo: 0 }, state_manager.fetch(:x))
      end
    end
  end
end

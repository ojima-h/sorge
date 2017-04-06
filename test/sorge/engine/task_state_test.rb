require 'test_helper'

module Sorge
  class Engine
    class TaskStateTest < SorgeTest
      def factory(name)
        TaskState.new(app.engine, name)
      end

      def test_init
        app.engine.state_manager.update('t1', foo: 0)

        state = factory('t1')
        assert_raises { state[:foo] }

        state.init
        assert_equal 0, state[:foo]
      end

      def test_save
        state = factory('t1')

        state.init
        state[:foo] = 1
        state.save

        assert_equal({ foo: 1 }, app.engine.state_manager.fetch('t1'))
        assert_raises { state[:foo] }
      end

      def test_queue
        state = factory('t1').tap(&:init)
        assert_equal [], state.queue
      end
    end
  end
end

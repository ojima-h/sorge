require 'test_helper'

module Sorge
  class Engine
    class TaskHandlerTest < SorgeTest
      def factory(name)
        TaskHandler.new(app.engine, name)
      end

      def stub_submit
        spy = []
        q = app.engine.event_queue
        q.stub(:submit, ->(*args) { spy << args }) do
          yield
        end
        spy
      end

      def test_notify
        handler = factory('test_window:t3')
        t = Time.now.to_i / 3 * 3

        spy = stub_submit do
          handler.notify('test_window:t1', t + 1)
          handler.notify('test_window:t1', t + 3)
          handler.notify('test_window:t2', t + 1)
          handler.notify('test_window:t2', t + 3)
        end

        assert_equal [[:run, time: t]], spy
      end
    end
  end
end

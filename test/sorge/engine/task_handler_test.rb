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
        app.engine.task_states['test_window:t3'][:task] = { foo: :bar }
        handler = factory('test_window:t3')
        t = Time.now.to_i / 3 * 3

        spy = []
        app.engine.task_runner.stub(:post, ->(*args) { spy << args }) do
          handler.notify('test_window:t1', t + 1)
          handler.notify('test_window:t1', t + 3)
          handler.notify('test_window:t2', t + 1)
          handler.notify('test_window:t2', t + 3)
        end

        ctx = TaskHandler::Context[t, { foo: :bar }]

        j = spy[0][0]
        assert_equal 'test_window:t3', j.name
        assert_equal ctx, j.context

        s1 = app.engine.task_states['test_window:t3'][:task]
        s2 = spy[0][0].state
        refute_equal s1.object_id, s2.object_id
      end

      def test_complete
        handler = factory('test_namespace:ns:t1')

        spy = []
        app.engine.event_queue.stub(:submit, ->(*args) { spy << args }) do
          handler.successed('job_id', 1, foo: :bar)
        end

        assert_equal [
          [:notify, name: 'test_namespace:ns:t1', time: 1, dest: 'test_namespace:ns:t2'],
          [:notify, name: 'test_namespace:ns:t1', time: 1, dest: 'test_namespace:t3'],
          [:notify, name: 'test_namespace:ns:t1', time: 1, dest: 'test_namespace:t4']
        ], spy

        assert_equal({ foo: :bar },
                     app.engine.task_states['test_namespace:ns:t1'][:task])
      end
    end
  end
end

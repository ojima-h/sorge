require 'test_helper'

module Sorge
  class DSL
    class TaskGraphTest < SorgeTest
      def test_reachable_edges
        task = Sorge.tasks['test_namespace:ns:t1']
        es = DSL.instance.task_graph.reachable_edges(task)
                .map { |e| [e.head.name, e.tail.name] }
        assert_equal [['test_namespace:ns:t1', 'test_namespace:ns:t2'],
                      ['test_namespace:ns:t2', 'test_namespace:t3'],
                      ['test_namespace:t3', 'test_namespace:t4'],
                      ['test_namespace:ns:t1', 'test_namespace:t3'],
                      ['test_namespace:ns:t1', 'test_namespace:t4']], es
      end
    end
  end
end

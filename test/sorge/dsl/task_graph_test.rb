require 'test_helper'

module Sorge
  class DSL
    class TaskGraphTest < SorgeTest
      def test_reachable_edges
        es = app.dsl.task_graph.reachable_edges(tasks['ns1:ns2:t1'])
                .map { |e| [e.head.name, e.tail.name] }
        assert_equal [['ns1:ns2:t1', 'ns1:ns2:t2'],
                      ['ns1:ns2:t2', 'ns1:t3'],
                      ['ns1:t3', 'ns1:t4'],
                      ['ns1:ns2:t1', 'ns1:t3'],
                      ['ns1:ns2:t1', 'ns1:t4']], es
      end
    end
  end
end

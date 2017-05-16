require 'test_helper'

module Sorge
  class DSL
    class TaskCollectionTest < SorgeTest
      def test_topological_sort
        index = app.tasks.each_key.with_index.to_h

        assert_operator index['t1'], :<, index['t2']
      end
    end
  end
end

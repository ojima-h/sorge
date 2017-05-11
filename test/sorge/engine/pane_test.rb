require 'test_helper'

module Sorge
  class Engine
    class PaneTest < SorgeTest
      def test_pane_entry
        e = PaneEntry['foo']
        assert_equal 'foo', e.task_name
        assert_equal 1, e.count

        e = PaneEntry['bar', 3]
        assert_equal 'bar', e.task_name
        assert_equal 3, e.count
      end

      def test_pane
        time = Time.now.to_i

        pane = Pane[time, PaneEntry['foo', 3], PaneEntry['bar']]
        assert_equal time, pane.time
        assert_equal 2, pane.length
        assert_equal %w(foo bar), pane.task_names

        assert_equal pane, Pane[time, ['foo', 3], 'bar']
        assert_equal pane, Pane[time, 'foo' => 3, 'bar' => 1]
      end

      def test_pane_add
        time = Time.now.to_i
        pane = Pane[time, 'foo' => 3, 'bar' => 1]

        assert_equal Pane[time, 'foo' => 3, 'bar' => 2], pane.add('bar')
        assert_equal Pane[time, 'foo' => 3, 'bar' => 1], pane
      end

      def test_pane_set
        t1 = Time.now.to_i - 10
        t2 = Time.now.to_i

        pane_set = PaneSet[Pane[t1, 'foo' => 3], Pane[t2, 'bar']]
        assert_equal 2, pane_set.length
        assert_equal [t1, t2], pane_set.times

        assert_equal pane_set, PaneSet[[t1, 'foo' => 3], [t2, 'bar']]

        pane_set2 = PaneSet[t1 => ['foo' => 3], t2 => %w(bar baz)]
        assert_equal Pane[t1, 'foo' => 3], pane_set2.first
        assert_equal %w(bar baz), pane_set2.to_a[1].task_names
      end

      def test_pane_set_add
        t1 = Time.now.to_i - 10
        t2 = Time.now.to_i
        pane_set = PaneSet[t1 => 'foo']

        assert_equal PaneSet[t1 => ['foo' => 1], t2 => ['bar' => 1]],
                     pane_set.add(t2, 'bar')
        assert_equal PaneSet[t1 => 'foo'], pane_set
      end

      def test_pane_set_partition
        t1 = Time.now.to_i - 10
        t2 = Time.now.to_i
        pane_set = PaneSet[t1 => 'foo', t2 => 'bar']

        a, b = pane_set.partition { |pane| pane.time < t1 + 5 }

        assert_equal PaneSet[t1 => ['foo' => 1]], a
        assert_equal PaneSet[t2 => ['bar' => 1]], b
      end
    end
  end
end

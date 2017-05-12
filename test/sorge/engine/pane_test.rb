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
        pane = Pane[now, PaneEntry['foo', 3], PaneEntry['bar']]
        assert_equal now, pane.time
        assert_equal 2, pane.length
        assert_equal %w(foo bar), pane.task_names

        assert_equal pane, Pane[now, ['foo', 3], 'bar']
        assert_equal pane, Pane[now, 'foo' => 3, 'bar' => 1]
      end

      def test_pane_add
        pane = Pane[now, 'foo' => 3, 'bar' => 1]

        assert_equal Pane[now, 'foo' => 3, 'bar' => 2], pane.add('bar')
        assert_equal Pane[now, 'foo' => 3, 'bar' => 1], pane
      end

      def test_pane_set
        pane_set = PaneSet[Pane[now - 10, 'foo' => 3], Pane[now, 'bar']]
        assert_equal 2, pane_set.length
        assert_equal [now - 10, now], pane_set.times

        assert_equal pane_set, PaneSet[[now - 10, 'foo' => 3], [now, 'bar']]

        pane_set2 = PaneSet[now - 10 => ['foo' => 3], now => %w(bar baz)]
        assert_equal Pane[now - 10, 'foo' => 3], pane_set2.first
        assert_equal %w(bar baz), pane_set2.to_a[1].task_names
      end

      def test_pane_set_add
        pane_set = PaneSet[now - 10 => 'foo']

        assert_equal PaneSet[now - 10 => ['foo' => 1], now => ['bar' => 1]],
                     pane_set.add(now, 'bar')
        assert_equal PaneSet[now - 10 => 'foo'], pane_set
      end

      def test_dump
        pane_set = PaneSet[now - 10 => ['foo' => 1], now => ['bar' => 2]]

        assert_equal(
          { ps: [{ tm: now - 10, es: [{ name: 'foo' }] },
                 { tm: now, es: [{ name: 'bar', n: 2 }] }] },
          pane_set.dump
        )

        assert_equal pane_set, PaneSet.restore(pane_set.dump)
      end
    end
  end
end

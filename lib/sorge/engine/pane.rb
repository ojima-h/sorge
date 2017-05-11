module Sorge
  class Engine
    PaneEntry = Struct.new(:task_name, :count) do
      def initialize(task_name, count = 1)
        super
      end

      def inc(n = 1)
        self.class[task_name, count + n]
      end
    end

    class Pane
      include Enumerable
      extend Forwardable

      # Pane[time, PaneEntry[:foo, 3], PaneEntry[:bar], ...]
      # Pane[time, ['foo', 3], 'bar', ...]
      # Pane[time, 'foo' => 3, 'bar' => 1, ...]
      def self.[](time, *entries)
        entries = entries.first if entries.first.is_a?(Hash)
        es = entries.map do |entry|
          next [entry.task_name, entry] if entry.is_a?(PaneEntry)
          task_name, count = entry
          [task_name, PaneEntry[task_name, count || 1]]
        end.to_h
        new(time, es)
      end

      def initialize(time, entries = {})
        @time = time
        @entries = entries
      end
      attr_reader :time, :entries
      protected :entries
      def_delegators :@entries, :include?, :empty?, :length
      def_delegator :@entries, :keys, :task_names
      def_delegator :@entries, :each_value, :each

      def ==(other)
        return false unless other.is_a?(Pane)
        @time == other.time && @entries == other.entries
      end

      def [](task_name)
        @entries[task_name]
      end

      def add(task_name)
        new_entry = @entries.fetch(task_name, PaneEntry[task_name, 0]).inc
        self.class.new(@time, @entries.merge(task_name => new_entry))
      end
    end

    class PaneSet
      include Enumerable
      extend Forwardable

      # PaneSet[Pane[...], ...]
      # PaneSet[[time1, ...], [time2, ...]]
      # PaneSet[time1 => [...], time2 => [...]]
      def self.[](*panes)
        panes = panes.first.map { |k, v| [k, *v] } if panes.first.is_a?(Hash)
        ps = panes.map do |pane|
          next [pane.time, pane] if pane.is_a?(Pane)
          time, *args = pane
          [time, Pane[time, *args]]
        end
        ps.reject! { |_, pane| pane.empty? }
        PaneSet.new(ps.to_h)
      end

      def initialize(panes = {})
        @panes = panes
      end
      attr_reader :panes
      protected :panes
      def_delegators :@panes, :[], :include?, :empty?, :length
      def_delegator :@panes, :keys, :times
      def_delegator :@panes, :each_value, :each

      def ==(other)
        return false unless other.is_a?(PaneSet)
        @panes == other.panes
      end

      def add(time, task_name)
        new_pane = @panes.fetch(time) { Pane.new(time) }.add(task_name)
        self.class.new(@panes.merge(time => new_pane))
      end

      def partition
        return to_enum(:partition) unless block_given?
        a, b = super
        [self.class[*a], self.class[*b]]
      end
    end
  end
end

module Sorge
  class DSL
    # Scope represents the namespace where a task is defined.
    class Scope
      include Enumerable

      def self.root
        @root ||= new('')
      end

      def self.current
        @current ||= root
      end

      # Evaluate block in given namespace
      def self.with(path)
        @current = Scope.new(path, current)
        yield
      ensure
        @current = @current.parent
      end

      def initialize(name, parent = nil)
        @name = name
        @parent = parent
      end
      attr_reader :name, :parent

      def root?
        parent.nil?
      end

      def each(&block)
        return if root? # root scope
        parent.each(&block)
        yield self
      end

      def path
        map(&:name).join(':')
      end

      def join(name)
        [*map(&:name), name].join(':')
      end
    end
  end
end

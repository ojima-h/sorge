module Sorge
  class DSL
    # Scope represents the namespace where a task is defined.
    class Scope < LinkedList
      def self.current
        @current ||= null
      end

      # Evaluate block in given namespace
      def self.with(name)
        @current = @current.conj(name)
        yield
      ensure
        @current = @current.tail
      end

      alias name head
      alias parent tail
      alias root? empty?

      def full_name
        to_a.reverse.join(':')
      end

      def join(name)
        [*to_a.reverse, name].join(':')
      end
    end
  end
end

module Sorge
  class DSL
    class LinkedList
      include Enumerable

      # @return [Enumerable] empty linked list
      def self.null
        @null ||= new(nil, nil)
      end

      def initialize(head, tail)
        @head = head
        @tail = tail
      end
      attr_reader :head, :tail

      def conj(obj)
        self.class.new(obj, self)
      end

      def empty?
        tail.nil?
      end

      def each(&block)
        return if empty?
        yield head
        tail.each(&block)
      end
    end
  end
end

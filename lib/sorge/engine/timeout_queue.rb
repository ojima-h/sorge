module Sorge
  class Engine
    class TimeoutQueue
      class ClosedQueueError < StandardError; end

      def initialize
        @mutex = Mutex.new
        @cv = Thread::ConditionVariable.new
        @queue = []
        @closed = false
      end

      def empty?
        @queue.empty?
      end

      def closed?
        @closed
      end

      def push(obj)
        @mutex.synchronize do
          raise ClosedQueueError if closed?
          @queue.push(obj)
          @cv.broadcast if @queue.length == 1
        end
        self
      end
      alias << push

      def shift(timeout = nil)
        @mutex.synchronize do
          ns_wait(timeout)
          raise ClosedQueueError if empty? && closed?
          @queue.shift
        end
      end

      def close
        @mutex.synchronize do
          @closed = true
          @cv.broadcast if @queue.empty?
        end
      end

      private

      # wait until new entry, timeout or closed
      def ns_wait(timeout)
        now = Time.now
        while empty? && !closed?
          t = timeout ? now + timeout - Time.now : nil
          return if !t.nil? && t <= 0 # timeout
          @cv.wait(@mutex, t)
        end
      end
    end
  end
end

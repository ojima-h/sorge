module Sorge
  class Engine
    class AsyncWorker
      def initialize(engine)
        @engine = engine

        @mutex = Mutex.new
        @queue = []
        @stop = false
        @stopped = Concurrent::Event.new
      end
      attr_reader :queue, :stop
      alias stop? stop

      def post(*args, &block)
        @mutex.synchronize do
          raise AlreadyStopped if @stop
          @queue << [args, block]
          @engine.worker.post { perform } if @queue.length == 1
        end
      end

      def stop
        @mutex.synchronize do
          @stop = true
          @stopped.set if @queue.empty?
        end
      end

      def wait_stop(timeout = nil)
        @stopped.wait(timeout)
      end

      def kill
        @stop = true
        @stopped.set
      end

      private

      def perform
        args, block = @mutex.synchronize { @queue.first }

        block.call(*args)

        @mutex.synchronize do
          @queue.shift
          return @stopped.set if @stop
          @engine.worker.post { perform } unless @queue.empty?
        end
      end
    end
  end
end

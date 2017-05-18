require 'test_helper'

module Sorge
  class Engine
    class AsyncWorkerTest < SorgeTest
      def test_post
        worker = AsyncWorker.new(app.engine, :default)

        q = []
        c = Concurrent::CountDownLatch.new(10)
        10.times do |i|
          worker.post(i) do |my_i|
            c.count_down
            q << my_i
          end
        end

        c.wait
        assert_equal (0..9).to_a, q
      end

      def test_stop
        worker = AsyncWorker.new(app.engine, :default)

        q = []
        b = Concurrent::CyclicBarrier.new(2)
        10.times do |i|
          worker.post(i) do |my_i|
            q << my_i
            if my_i == 5
              b.wait
              b.wait
            end
          end
        end
        b.wait
        worker.stop
        b.wait
        worker.wait_stop

        assert_equal (0..5).to_a, q
        assert_equal 4, worker.queue.length

        assert_raises AlreadyStopped do
          worker.post { foo }
        end
      end
    end
  end
end

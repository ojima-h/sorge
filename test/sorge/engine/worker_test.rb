require 'test_helper'

module Sorge
  class Engine
    class WorkerTest < SorgeTest
      def test_worker
        t1 = nil
        SorgeTest.hook('test_worker:t1') do
          t1 = Thread.current.object_id
        end

        t2 = nil
        SorgeTest.hook('test_worker:t2') do
          t2 = Thread.current.object_id
        end

        invoke('test_worker:t0')

        assert_equal t1, t2
      end
    end
  end
end

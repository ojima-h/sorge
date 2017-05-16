require 'test_helper'

module Sorge
  class Engine
    class JobflowStatusTest < SorgeTest
      def test_dump
        jobflow_status = JobflowStatus.new
        jobflow_status['t1'] = TaskStatus.new.tap do |s|
          s.state = { x: 1 }
          s.trigger_state = { y: 2 }
          s.pending = PaneSet.new
          s.running = [Pane[now, 'foo', 'bar']]
          s.finished = [now + 10]
          s.position = now + 10
        end
        jobflow_status['t2'] = TaskStatus.new

        assert_equal(
          {
            't1' => {
              st: { x: 1 },
              tst: { y: 2 },
              run: [{ tm: now, es: [{ name: 'foo' }, { name: 'bar' }] }],
              fin: [now + 10],
              pos: now + 10
            }
          },
          jobflow_status.dump
        )

        restored = JobflowStatus.restore(jobflow_status.dump)
        assert_equal ['t1'], restored.keys
        assert_equal jobflow_status['t1'], restored['t1']
      end
    end
  end
end

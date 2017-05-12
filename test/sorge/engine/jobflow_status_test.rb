require 'test_helper'

module Sorge
  class Engine
    class JobflowStatusTest < SorgeTest
      def test_dump
        t = Time.now.to_i
        jobflow_status = JobflowStatus.new
        jobflow_status['t1'] = TaskStatus.new.tap do |s|
          s.state = { x: 1 }
          s.trigger_state = { y: 2 }
          s.pending = PaneSet.new
          s.running = [Pane[t, 'foo', 'bar']]
          s.finished = [t + 10]
          s.position = t + 10
        end
        jobflow_status['t2'] = TaskStatus.new

        assert_equal(
          {
            't1' => {
              st: { x: 1 },
              tst: { y: 2 },
              run: [{ tm: t, es: [{ name: 'foo' }, { name: 'bar' }] }],
              fin: [t + 10],
              pos: t + 10
            }
          },
          jobflow_status.dump
        )

        restored = JobflowStatus.restore(jobflow_status.dump)
        assert_equal jobflow_status['t1'], restored['t1']

        all_task_names = Sorge.tasks.each_task.map(&:first)
        assert_equal all_task_names.sort, restored.keys.sort
      end
    end
  end
end

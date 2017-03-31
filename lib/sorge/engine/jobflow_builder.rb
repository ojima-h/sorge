module Sorge
  class Engine
    module JobflowBuilder
      class << self
        def build(driver, root_task, params)
          jobflow = Jobflow.new(driver)
          jobflow.add(root_task, JobStatus.pending, params)
          root_task.reachable_edges
                   .group_by(&:tail)
                   .each do |task, edges|
                     status = JobStatus.unscheduled(edges.count)
                     jobflow.add(task, status)
                   end
          jobflow
        end
      end
    end
  end
end

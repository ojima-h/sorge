module Sorge
  class Engine
    class JobflowStatus < Hash
      def dump
        hash = {}
        each do |task_name, task_status|
          h = task_status.dump
          hash[task_name] = h unless h.empty?
        end
        hash
      end

      def self.restore(hash)
        o = new
        Sorge.tasks.each_task do |task_name, _|
          o[task_name] =
            if (status = hash[task_name])
              TaskStatus.restore(status)
            else
              TaskStatus.new
            end
        end
        o
      end
    end
  end
end

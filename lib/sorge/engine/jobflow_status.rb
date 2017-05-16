module Sorge
  class Engine
    class JobflowStatus < Hash
      def active?
        each_value.any?(&:active?)
      end

      def complete?
        each_value.all?(&:complete?)
      end

      def pending?
        !active? && !complete?
      end

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
        DSL.task_definition.each do |task_name, definition|
          next unless definition.klass <= DSL::Task
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

module Sorge
  class Engine
    class JobflowStatus < Hash
      def [](key)
        super || TaskStatus.new.freeze
      end

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
        hash.each do |task_name, status|
          next unless DSL.task_definition.include?(task_name)
          o[task_name] = TaskStatus.restore(status)
        end
        o
      end
    end
  end
end

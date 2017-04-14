module Sorge
  class DSL
    module Core
      extend Concern
      extend Forwardable

      class_methods do
        def init(dsl, name)
          @dsl = dsl
          @name = name
          @initialized = true
        end
        attr_reader :name

        def initialized?
          defined?(@initialized) && @initialized
        end

        def inspect
          return super unless initialized?
          "Task<#{name}>"
        end

        # Return a list of Mixin objects included.
        def super_mixin
          ancestors[1..-1].find { |o| o <= Core }
        end
      end

      def initialize(context)
        @context = context
      end
      attr_reader :context
      def_delegators :context, :state, :job
      def_delegators :job, :stash

      def time
        @time ||= Time.at(context.time)
      end

      def run
        nil
      end

      def to_s
        task.name
      end

      def to_h
        { name: task.name, time: context.time, state: state }
      end

      def inspect
        format('#<Task:0x00%x name=%s time=%d>',
               object_id << 1, task.name, time)
      end

      def task
        self.class
      end
      def_delegators :task, :name

      def logger
        Sorge.logger
      end
    end
  end
end

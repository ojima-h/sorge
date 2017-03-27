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

      def_delegators :context, :job
      def_delegators :job, :stash, :params

      def to_s
        task.name + ' ' + params.to_json
      end

      def inspect
        format('#<Task:0x00%x name=%s params=%s>',
               object_id << 1, task.name, params)
      end

      def task
        self.class
      end

      def logger
        Sorge.logger
      end
    end
  end
end

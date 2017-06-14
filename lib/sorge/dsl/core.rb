module Sorge
  class DSL
    module Core
      extend Concern
      extend Forwardable

      class_methods do
        extend Forwardable

        def init(app, name)
          @app = app
          @name = name
          @scope = Scope.null
          @initialized = true
        end
        attr_reader :app, :name, :scope

        def initialized?
          defined?(@initialized) && @initialized
        end

        def inspect
          return super unless initialized?
          "Task<#{name}>"
        end

        # Return a list of Mixin objects included.
        def super_mixins
          ancestors.select { |o| o <= Core && o.initialized? }
        end
        def super_mixin
          ancestors[1..-1].find { |o| o <= Core }
        end

        def in_scope(scope)
          orig_scope = @scope
          @scope = scope
          yield
        ensure
          @scope = orig_scope
        end
      end

      def initialize(context)
        @context = context
      end
      attr_reader :context
      def_delegators :context, :time, :state, :pane
      def_delegators :task, :app
      def_delegators :app, :env, :dryrun?

      def run
        nil
      end

      def dryrun
        nil
      end

      def to_s
        task.name
      end

      def inspect
        format('#<Task:0x00%x name=%s time=%s>',
               object_id << 1, task.name, time)
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

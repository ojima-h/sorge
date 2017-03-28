module Sorge
  class DSL
    class TaskManager
      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
      end

      # @param name [String, Symbol] task name
      # @param klass [Class] task class (Task or Mixin)
      # @param block [Proc] task definition
      def define(name, klass, &block)
        name = name.to_s
        task = (@tasks[name] ||= klass.create(@dsl, name))

        task.class_eval(&block) if block_given?
        @dsl.task_graph.add(task) if task < Task
      end

      def [](name, scope = Scope.null)
        name = name.to_s
        if scope.root? && !@tasks.include?(name)
          raise NameError, "undefined task #{name}"
        end
        @tasks[scope.join(name)] || self[name, scope.parent]
      end
    end
  end
end

module Sorge
  class DSL
    class TaskManager
      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
      end

      def define(name, klass, &block)
        name = name.to_s
        task = (@tasks[name] ||= klass.create(name, @dsl))

        task.enhance(&block)
        @dsl.task_graph.add(task) if task < Task
      end

      def [](name, scope = Scope.null)
        name = name.to_s
        if scope.root? && !@tasks.include?(name)
          raise NameError, "uninitialized task #{name}"
        end
        @tasks[scope.join(name)] || self[name, scope.parent]
      end
    end
  end
end

module Sorge
  class DSL
    class TaskManager
      extend Forwardable

      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
      end
      def_delegators :@tasks, :include?, :each, :keys

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
      alias validate_name []

      def each_task(&block)
        enum = Enumerator.new do |y|
          @tasks.each do |task_name, task|
            y << [task_name, task] if task < Task
          end
        end
        block_given? ? enum.each(&block) : enum
      end
    end
  end
end

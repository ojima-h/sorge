module Sorge
  class DSL
    class TaskCollection
      Edge = Struct.new(:head, :tail)

      extend Forwardable
      include Enumerable

      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
        @matrix = nil
      end
      def_delegators :@tasks, :each, :each_key

      def build
        build_all_tasks
        @matrix = build_matrix
        @tasks = topological_sort
        self
      end

      def [](name, scope = Scope.null)
        name = name.to_s
        if scope.root? && !DSL.task_definition.include?(name)
          raise NameError, "undefined task #{name}"
        end
        fetch(scope.join(name)) || self[name, scope.parent]
      end
      alias validate_name []

      def each_task(&block)
        select { |_, task| task < Task }.each(&block)
      end

      private

      def fetch(task_name)
        return nil unless DSL.task_definition.include?(task_name)

        @tasks[task_name] ||= \
          DSL.task_definition[task_name].create(@dsl.app)
      end

      def build_all_tasks
        DSL.task_definition.each_key(&method(:fetch))
      end

      def build_matrix
        matrix = Hash.new { |hash, key| hash[key] = {} }
        each_task do |task_name, task|
          task.upstreams.each do |up_task_name, up_task|
            matrix[up_task_name][task_name] = Edge[up_task, task]
          end
        end
        matrix
      end

      def topological_sort
        sorted = {}
        @tasks.each_key do |task_name|
          next unless @matrix[task_name].empty? # only root tasks
          iter_topological_sort(task_name, sorted)
        end
        sorted
      end

      def iter_topological_sort(task_name, sorted)
        return if sorted.include?(task_name)

        task = @tasks[task_name]
        task.upstreams.each_key do |up_task_name|
          iter_topological_sort(up_task_name, sorted)
        end
        sorted[task_name] = task
      end
    end
  end
end

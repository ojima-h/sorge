module Sorge
  class DSL
    class TaskManager
      def initialize(dsl)
        @dsl = dsl
        @tasks = {}
      end

      def define(path, klass, &block)
        @tasks[path] ||= klass.create(path, @dsl)
        @tasks[path].enhance(&block)
      end

      def [](name, scope = Scope.root)
        raise NameError, "uninitialized task #{name}" if scope.nil?
        @tasks[scope.join(name)] || self[name, scope.parent]
      end
    end
  end
end

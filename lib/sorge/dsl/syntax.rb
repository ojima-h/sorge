module Sorge
  class DSL
    module Syntax
      def namespace(path, &block)
        Scope.with(path, &block)
      end

      def task(name, &block)
        path = Scope.current.join(name)
        Sorge::DSL.current.task_manager.define(path, Task, &block)
      end

      def mixin(name, &block)
        path = Scope.current.join(name)
        Sorge::DSL.current.task_manager.define(path, Mixin, &block)
      end

      def global_mixin(&block)
        Sorge::DSL.current.global_mixin.class_eval(&block)
      end
    end
  end
end

extend Sorge::DSL::Syntax

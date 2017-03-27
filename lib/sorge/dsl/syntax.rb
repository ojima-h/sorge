module Sorge
  class DSL
    module Syntax
      def namespace(name, &block)
        Scope.with(name, &block)
      end

      def task(name, &block)
        full_name = Scope.current.join(name)
        Sorge::DSL.current.task_manager.define(full_name, Task, &block)
      end

      def mixin(name, &block)
        full_name = Scope.current.join(name)
        Sorge::DSL.current.task_manager.define(full_name, Mixin, &block)
      end

      def global(&block)
        Sorge::DSL.current.global.class_eval(&block)
      end
    end
  end
end

extend Sorge::DSL::Syntax

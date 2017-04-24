module Sorge
  class DSL
    module Syntax
      def namespace(name, &block)
        Scope.with(name, &block)
      end

      def task(name, &block)
        full_name = Scope.current.join(name)
        Sorge::DSL.instance.task_manager.define(full_name, Task, &block)
      end

      def mixin(name, &block)
        full_name = Scope.current.join(name)
        Sorge::DSL.instance.task_manager.define(full_name, Mixin, &block)
      end

      def global(&block)
        Sorge::DSL.instance.global.class_eval(&block)
      end

      def require_all(path)
        Dir.glob(File.join(path, '**/*.rb')).each do |file_path|
          require(file_path) if File.file?(file_path)
        end
      end
    end
  end
end

extend Sorge::DSL::Syntax

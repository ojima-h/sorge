module Sorge
  class DSL
    class TaskDefinition < Hash
      Entry = Struct.new(:task_name, :klass, :bodies) do
        def initialize(*args)
          super
          self.bodies ||= []
        end

        def create(app)
          t = klass.create(app, task_name)
          bodies.each do |body|
            t.in_scope(body.scope || Scope.null) do
              t.class_eval(&body.block)
            end
          end
          t
        end
      end
      Body = Struct.new(:block, :scope)

      def initialize
        super
        define(:global, Mixin)
      end

      def define(task_name, klass, scope = nil, &block)
        task_name = task_name.to_s
        e = (self[task_name] ||= Entry[task_name])

        e.klass ||= klass
        raise Error, "#{task_name} is not a #{klass}" unless e.klass == klass

        e.bodies << Body[block, scope] if block_given?
      end
    end
  end
end

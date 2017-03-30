module Sorge
  class DSL
    class Task
      include Base

      class << self
        def create(dsl, name)
          Class.new(self) do
            include dsl.global
            init(dsl, name)
          end
        end
      end

      def setup
        assign_params
        call_action(:setup)
      end

      def execute
        call_action(:action)
      end
    end
  end
end

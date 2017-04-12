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

      def invoke
        execute
        successed
        true
      rescue => error
        failed(error)
        false
      end

      def successed
        Sorge.logger.info("successed: #{name} (#{time})")
      end

      def failed(error)
        Sorge.logger.error("failed: #{name} (#{time})")
        Sorge.logger.error(Util.format_error_info(error))
      end
    end
  end
end

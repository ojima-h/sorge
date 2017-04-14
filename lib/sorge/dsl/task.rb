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
        call_hook(:setup)
      end

      def invoke
        Sorge.logger.info("start: #{name} (#{time})")
        run
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

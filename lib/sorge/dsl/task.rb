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

      def invoke
        invoke_before
        run unless dryrun? && !support_dryrun
        invoke_successed
        true
      rescue => error
        invoke_failed(error)
        false
      ensure
        invoke_after
      end

      def invoke_before
        Sorge.logger.info("start: #{name} (#{time})")
        call_hook(:before)
      end

      def invoke_successed
        Sorge.logger.info("successed: #{name} (#{time})")
        call_hook(:successed)
      end

      def invoke_failed(error)
        Sorge.logger.error("failed: #{name} (#{time})")
        Sorge.logger.error(Util.format_error_info(error))
        call_hook(:failed, error)
      end

      def invoke_after
        call_hook(:after)
      end
    end
  end
end

module Sorge
  class DSL
    TaskContext = Struct.new(:app, :time, :state)

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

      def initialize(context)
        super
        call_hook(:setup)
      end

      def invoke
        invoke_before
        invoke_run
        invoke_successed
        true
      rescue => error
        invoke_failed(error)
        false
      ensure
        invoke_after
      end

      def invoke_before
        Sorge.logger.info("start: #{task.name} '#{time}'")
        call_hook(:before) unless dryrun?
      end

      def invoke_run
        if dryrun?
          dryrun if respond_to?(:dryrun)
        else
          run
        end
      end

      def invoke_successed
        Sorge.logger.info("successed: #{task.name} '#{time}'")
        call_hook(:successed) unless dryrun?
      end

      def invoke_failed(error)
        Sorge.logger.error("failed: #{task.name} '#{time}'")
        Sorge.logger.error(Util.format_error_info(error))
        call_hook(:failed, error) unless dryrun?
      end

      def invoke_after
        call_hook(:after) unless dryrun?
      end
    end
  end
end

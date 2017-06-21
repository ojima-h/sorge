module Sorge
  class DSL
    TaskContext = Struct.new(:time, :state, :pane, :position) do
      def initialize(*args)
        super
        self.state ||= {}
        self.pane ||= Engine::Pane[time]
      end
    end

    class Task
      include Base

      class SkipError < StandardError; end

      class << self
        def create(app, name)
          Class.new(self) do
            init(app, name)
            use :global
          end
        end
      end

      def skip
        Sorge.logger.info("skip: #{task.name} '#{time}'")
        raise SkipError
      end

      def invoke
        invoke_setup
        invoke_before
        invoke_run
      rescue SkipError
        false
      rescue => error
        invoke_failed(error)
        false # always false
      else
        invoke_successed # true if hook is successed
      ensure
        invoke_finally
      end

      def invoke_setup
        call_hook(:setup)
      end

      def invoke_before
        Sorge.logger.info("start: #{task.name} '#{time}'")
        call_hook(:before) unless dryrun?
      end

      def invoke_run
        if dryrun?
          dryrun
        else
          run
        end
      end

      def invoke_with_error_handler(tag)
        yield
        true
      rescue => error
        Sorge.logger.error("error while `#{tag}` hook: #{task.name} '#{time}'")
        Sorge.logger.error(Util.format_error_info(error, 10))
        false
      end

      def invoke_successed
        Sorge.logger.info("successed: #{task.name} '#{time}'")
        invoke_with_error_handler(:successed) do
          call_hook(:successed) unless dryrun?
        end
      end

      def invoke_failed(error)
        Sorge.logger.error("failed: #{task.name} '#{time}'")
        Sorge.logger.error(Util.format_error_info(error))
        invoke_with_error_handler(:failed) do
          call_hook(:failed, error) unless dryrun?
        end
      end

      def invoke_finally
        invoke_with_error_handler(:finally) do
          call_hook(:finally) unless dryrun?
        end
      end
    end
  end
end

require 'sorge/cli/common'

module Sorge
  class CLI
    class Run
      include Common

      def initialize(options)
        @options = options
        @app = build_app(options)
      end

      def run(task, time)
        @app.resume(@options['savepoint']) if @options['savepoint']
        @app.run(task, Util::Time(time))
      end

      def execute(task, time)
        context = DSL::TaskContext[@app, Util::Time(time), {}]
        @app.tasks[task].new(context).invoke
      end

      def submit(task, time)
        client = @app.server.client
        client.call('jobflow.submit', task, Util::Time(time).to_f)
      end
    end
  end
end

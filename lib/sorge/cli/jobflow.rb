require 'sorge/cli/common'

module Sorge
  class CLI
    class Jobflow
      include Common

      def initialize(options)
        @options = options
        @app = build_app(options)
      end

      def run(task, time)
        @app.resume(@options['resume']) if @options['resume']
        @app.run(task, Util::Time(time))
      end

      def execute(task, time)
        context = DSL::TaskContext[Util::Time(time)]
        @app.tasks[task].new(context).invoke
      end

      def submit(task, time)
        client = @app.server.client
        client.call('jobflow.submit', task, Util::Time(time).to_f)
      end

      def status
        client = @app.server.client
        puts client.call('jobflow.status')
      end
    end
  end
end

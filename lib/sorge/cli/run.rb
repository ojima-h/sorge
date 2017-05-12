require 'sorge/cli/parser'

module Sorge
  class CLI
    class Run
      def initialize(app, task_name, time, args, options)
        @app = app
        @task_name = task_name
        @time = Util::Time(time)
        @params = Parser.parse(args)
        @options = options

        @app.resume(@options['savepoint']) if @options['savepoint']
      end

      def run
        @app.submit(@task_name, @time).shutdown
      end

      def exec
        Engine::TaskHandler.new(@app.engine, @task_name).to_job(@time).invoke
      end
    end
  end
end

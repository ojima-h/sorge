require 'sorge/cli/parser'

module Sorge
  class CLI
    class Run
      def initialize(app, task_name, time, args, options)
        @app = app
        @task_name = task_name
        @time = Util.parse_time(time)
        @params = Parser.parse(args)
        @options = options
      end

      def run
        @app.submit(@task_name, @time).shutdown
      end
    end
  end
end

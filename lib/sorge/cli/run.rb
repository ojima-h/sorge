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
        @app.run(@task_name, @time)
      end
    end
  end
end

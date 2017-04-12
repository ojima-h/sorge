require 'sorge/cli/parser'

module Sorge
  class CLI
    class Run
      def initialize(app, task_name, time, args, options)
        @app = app
        @task_name = task_name
        @time = parse_time(time)
        @params = Parser.parse(args)
        @options = options
      end

      def run
        @app.engine.driver.run(@task_name, @time)
      end

      def parse_time(time)
        if time =~ /\A\d+$\z/
          time.to_i
        else
          Time.parse(time).to_i
        end
      end
    end
  end
end

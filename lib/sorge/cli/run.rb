require 'sorge/cli/parser'

module Sorge
  class CLI
    class Run
      def initialize(app, task_name, args, options)
        @app = app
        @task = app.dsl.task_manager[task_name]
        @params = Parser.parse(args)
        @options = options
      end

      def run
        @app.engine.driver.run(@task, @params)
      end
    end
  end
end

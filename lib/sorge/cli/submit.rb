require 'sorge/cli/parser'

module Sorge
  class CLI
    class Submit
      def initialize(config, task_name, time, args, options)
        @config = config
        @task_name = task_name
        @time = Util.parse_time(time)
        @params = Parser.parse(args)
        @options = options
      end

      def run
        Server.client(@config).call(:submit, name: @task_name, time: @time)
        puts 'ok'
      end
    end
  end
end

require 'sorge/cli/common'
require 'sorge/cli/daemons'

module Sorge
  class CLI
    class Server
      include Common

      def initialize(options)
        @options = options
        @app = build_app(options)
        @daemons = Daemons.new(@app, @options['daemonize'])
      end

      def start
        puts 'Starting sorge server...'
        @daemons.start

        @app.resume(@options['savepoint']) if @options['savepoint']
        @app.start
      end

      def stop
        stop_jobflow
        @daemons.stop
      rescue => error
        puts Util.format_error_info(error, 10)
        puts
        puts 'Failed to stop application.'
        puts 'Trying to force kill...'
        @daemons.stop
      end

      def kill
        @daemons.stop
      end

      private

      def stop_jobflow
        client = @app.server.client
        client.call('jobflow.stop')

        puts 'waiting to stop sorge server ...'

        expiration = Time.now + @options.fetch('timeout', 60)
        sleep 1 until client.call('jobflow.wait_stop') || Time.now >= expiration
      end
    end
  end
end

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

        @app.resume(@options['resume']) if @options['resume']
        @app.start
      end

      def stop
        stop_jobflow
        stop_server
        stop_process
      rescue => error
        $stderr.puts Util.format_error_info(error, 10)
        $stderr.puts
        $stderr.puts 'Failed to stop application.'
        $stderr.puts 'Trying to force kill...'
        stop_process
      end

      def kill
        stop_process
      end

      def ping
        client = @app.server.client
        client.call('ping')
        puts 'ok'
      rescue => e
        abort "ng (#{e})"
      end

      private

      def stop_jobflow
        client = @app.server.client
        client.call('jobflow.stop')

        $stderr.puts 'waiting to stop sorge server ...'

        expiration = Time.now + @options.fetch('timeout', 60)
        sleep 1 until client.call('jobflow.wait_stop') || Time.now >= expiration
      end

      def stop_server
        @daemons.signal(:INT)
      end

      def stop_process
        @daemons.stop
      end
    end
  end
end

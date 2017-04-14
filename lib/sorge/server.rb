module Sorge
  class Server
    def self.client(config)
      JsonRPCCLient.new(config.get('core.socket_file'))
    end

    def initialize(app)
      @app = app
      @socket_file = app.config.get('core.socket_file')
      @client = nil
      @running = false
    end

    def start
      @running = true
      JsonRPCServer.new(@socket_file, self).start
    ensure
      @running = false
    end

    def call(method, params = {})
      JsonRPCCLient.new(@socket_file).call(method, params)
    end

    def stop
      call(:stop) if @running
    end

    #
    # Handlers
    #
    def handle_submit(name:, time:)
      @app.submit(name, Util.parse_time(time))
    end

    #
    # Backend
    #
    class JsonRPCServer
      def initialize(socket_file, server)
        @socket_file = socket_file
        @server = server
        @stopped = false
      end

      def start
        Sorge.logger.info('Start sorge server')
        Sorge.logger.info("pid: #{Process.pid}, socket: #{@socket_file}")
        FileUtils.makedirs(File.dirname(@socket_file))
        catch :stop do
          Socket.unix_server_loop(@socket_file) do |socket, _|
            process_connection(socket)
            break if @stopped
          end
        end
      end

      private

      def process_connection(socket)
        while (request = socket.gets)
          socket.puts process_request(request)
          socket.flush
          break if @stopped
        end
      ensure
        socket.close
      end

      def process_request(request)
        result = dispatch(JSON.parse(request))
        JSON.dump(result: result)
      rescue => error
        JSON.dump(process_error(error))
      end

      def dispatch(request)
        method = request['method']
        params = request['params'] || {}

        if method == 'stop'
          @stopped = true
          return
        end

        @server.send('handle_' + method, Util.symbolize_keys(params))
      end

      def process_error(error)
        Sorge.logger.error('server error:')
        Sorge.logger.error(Util.format_error_info(error))

        { message: error.class + ': ' + error.message,
          backtrace: error.backtrace }
      end
    end

    class JsonRPCCLient
      class Error < StandardError; end

      def initialize(socket_file)
        @socket_file = socket_file
      end

      def call(method, params = {})
        result = send_method(method, params)
        raise_error(result['error']) if result['error']
        Util.symbolize_keys(result['result'])
      end

      private

      def send_method(method, params)
        request = JSON.dump(method: method, params: params)
        JSON.parse(send_request(request))
      end

      def send_request(body)
        wait_server
        Socket.unix(@socket_file) do |socket|
          socket.puts(body)
          socket.flush
          socket.gets
        end
      end

      def wait_server
        10.times do |i|
          break if File.exist?(@socket_file)
          sleep 0.01 * 2**i
        end
      end

      def raise_error(error_info)
        e = Error.new(error_info['message'])
        e.set_backtrace(error_info['backtrace'])
        raise e
      end
    end
  end
end

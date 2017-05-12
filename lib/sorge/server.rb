module Sorge
  class Server
    class Error < StandardError; end

    def self.client(config)
      JsonRPCCLient.new(config)
    end

    def initialize(app)
      @app = app
      @client = nil
      @running = false
    end

    def start
      @running = true
      JsonRPCServer.new(@app.config, self).start
    ensure
      @running = false
    end

    def call(method, params = {})
      JsonRPCCLient.new(@app.config).call(method, params)
    end

    def stop
      call(:stop) if @running
    end

    #
    # Handlers
    #
    def handle_submit(name:, time:)
      @app.submit(name, Util::Time(time))
    end

    #
    # Backend
    #
    class JsonRPCServer
      def initialize(config, server)
        @port = config.server_rpc_port
        @server = server
        @stopped = false
      end

      def start
        Sorge.logger.info('Start sorge server')
        Sorge.logger.info("pid: #{Process.pid}, port: #{@port}")
        catch :stop do
          ServerSocket.tcp_server_loop(@port) do |socket, _|
            process_connection(socket)
            break if @stopped
          end
        end
      rescue Exception => exception
        Sorge.logger.error(Util.format_error_info(exception))
        raise
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
        JSON.dump(error: process_error(error))
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

        { message: error.class.to_s + ': ' + error.message,
          backtrace: error.backtrace }
      end
    end

    class JsonRPCCLient
      def initialize(config)
        @port = config.server_rpc_port
        @retry_count = config.server_rpc_retry
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
        connect do |socket|
          socket.puts(body)
          socket.flush
          socket.gets
        end
      end

      def connect
        socket = with_retry(@retry_count) { TCPSocket.new(@host, @port) }
        yield socket
      ensure
        socket.close
      end

      def with_retry(retry_count)
        i = 0
        begin
          yield
        rescue
          raise if (i += 1) > retry_count
          sleep 1
          retry
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

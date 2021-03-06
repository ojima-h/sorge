module Sorge
  class Server
    PATH = '/RPC2'.freeze

    def initialize(app)
      @app = app
      @server = nil
    end

    def start
      require 'webrick'
      require 'xmlrpc/server'

      @server = build_webrick
      @server.mount(PATH, build_servlet)
      write_server_info
      @server.start
    ensure
      delete_server_info
    end

    def stop
      @server.shutdown if @server
    end

    def status
      @server.status if @server
    end

    def client
      require 'xmlrpc/client'

      port = read_server_info[:port]
      XMLRPC::Client.new3(port: port)
    end

    private

    def build_webrick
      WEBrick::HTTPServer.new(
        Port: 0,
        AccessLog: []
      )
    end

    def build_servlet
      servlet = XMLRPC::WEBrickServlet.new
      servlet.add_handler('ping') { 'pong' }
      JobflowHandler.add_to(servlet, @app)
      servlet
    end

    def read_server_info
      path = @app.config.server_info_path
      YAML.load_file(path)
    end

    def write_server_info
      path = @app.config.server_info_path
      FileUtils.makedirs(File.dirname(path))
      File.write(path, YAML.dump(port: @server.config[:Port]))
    end

    def delete_server_info
      path = @app.config.server_info_path
      File.delete(path)
    rescue
      nil
    end

    class JobflowHandler
      WAIT_STOP_TIMEOUT = 10

      def self.interface
        XMLRPC.interface('jobflow') do
          meth 'void submit(string, time)'
          meth 'struct status()'
          meth 'void stop()'
          meth 'void wait_stop()'
        end
      end

      def self.add_to(rpc_server, app)
        rpc_server.add_handler(interface, new(app))
      end

      def initialize(app)
        @app = app
      end

      def submit(task_name, time)
        @app.submit(task_name, Util::Time(time))
        true
      end

      def status
        YAML.dump(@app.engine.jobflow_operator.status.dump)
      end

      def stop
        @app.engine.stop
        true
      end

      def wait_stop
        @app.engine.wait_stop(WAIT_STOP_TIMEOUT)
      end
    end
  end
end

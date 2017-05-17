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

      s = XMLRPC::WEBrickServlet.new
      JobflowHandler.add_to(s, @app)

      @server = WEBrick::HTTPServer.new(Port: 0)
      @server.mount(PATH, s)
      write_server_info
      @server.start
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

    def read_server_info
      path = @app.config.server_info_path
      YAML.load_file(path)
    end

    def write_server_info
      path = @app.config.server_info_path
      File.write(path, YAML.dump(port: @server.config[:Port]))
    end

    class JobflowHandler
      def self.interface
        XMLRPC.interface('jobflow') do
          meth 'void submit(string, time)'
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
      end
    end
  end
end

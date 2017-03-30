require 'net/http'
require 'openssl'
require 'uri'

require 'sorge/cli/parser'

module Sorge
  class CLI
    class Submit
      def initialize(config, task_name, args, options)
        @config = config
        @task_name = task_name
        @params = Parser.parse(args)
        @options = options
      end

      def run
        post('jobs', task: @task_name, params: @params)
        puts 'ok'
      end

      def post(path, params = {})
        uri = URI.parse(File.join(@config.get('server.uri'), path))
        Net::HTTP.new(uri.host, uri.port).start do |http|
          configure_ssl(http) if uri.scheme == 'https'
          header = { 'content_type' => 'application/json' }
          http.post(uri.path, JSON.dump(params), header).tap(&:value)
        end
      end

      def configure_ssl(http)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end

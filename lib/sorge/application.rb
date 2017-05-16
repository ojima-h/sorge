module Sorge
  class Application
    extend Forwardable

    DEFAULT_PROCESS_DIR = './var/sorge'.freeze
    DEFAULT_CONFIG = {
      heartbeat_interval: 1,
      process_dir:        DEFAULT_PROCESS_DIR,
      savepoint_path:     File.join(DEFAULT_PROCESS_DIR, 'savepoints'),
      savepoint_interval: 10,
      server_rpc_port:    39_410,
      server_rpc_retry:   3
    }.freeze

    def initialize(options = {})
      @options = options
      @config = OpenStruct.new(DEFAULT_CONFIG)

      @dsl = DSL.new(self)
      @plugins = Plugin.build(self)
      load_sorgefile
      @dsl.tasks.build
      setup

      @engine = Engine.new(self)
      @server = Server.new(self)
    end
    attr_reader :config, :dsl, :engine, :config, :server, :plugins
    def_delegators :@dsl, :tasks
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run, :resume

    def setup
      Sorge.setup.each { |block| block.call(self) }
    end

    def shutdown
      @server.stop
      @engine.driver.shutdown
    end

    def kill
      @server.stop
      @engine.driver.kill
    end

    def name
      config.app_name
    end

    def env
      @options[:env]
    end

    def dryrun?
      @options[:dryrun]
    end

    private

    def load_sorgefile
      sorgefile = find_sorgefile
      require(File.expand_path(sorgefile)) if sorgefile
    end

    def find_sorgefile
      return @options[:sorgefile] if @options[:sorgefile]
      return 'Sorgefile.rb' if File.file?('Sorgefile.rb')
      nil
    end
  end
end

require 'sorge/engine'
require 'sorge/plugin'
require 'sorge/server'

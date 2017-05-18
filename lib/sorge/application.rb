module Sorge
  class Application
    extend Forwardable

    DEFAULT_PROCESS_DIR = './var/sorge'.freeze
    DEFAULT_CONFIG = {
      app_name:           'sorge',
      heartbeat_interval: 1,
      process_dir:        DEFAULT_PROCESS_DIR,
      savepoint_path:     File.join(DEFAULT_PROCESS_DIR, 'savepoints'),
      server_info_path:   File.join(DEFAULT_PROCESS_DIR, 'server-info.yml')
    }.freeze

    def initialize(options = {})
      @options = options
      @config = OpenStruct.new(DEFAULT_CONFIG)

      @dsl = DSL.new(self)
      @engine = Engine.new(self)
      @server = Server.new(self)

      # In Sorgefile:
      #   - setup blocks are registered
      #   - tasks are declared
      #   - plugins are loaded
      load_sorgefile

      @plugins = Plugin.build(self)
      @dsl.tasks.build
      setup
    end
    attr_reader :config, :dsl, :engine, :server, :plugins
    def_delegators :@dsl, :tasks
    def_delegators :'@engine', :submit, :resume, :run, :stop, :wait_stop

    def setup
      Sorge.setup.each { |block| block.call(self) }
      FileUtils.makedirs(@config.process_dir)
      setup_trap
    end

    def start
      @engine.start
      @server.start
    end

    def stop
      Sorge.logger.info('stopping sorge jobflow...')
      @server.stop
      @engine.stop
      @engine.wait_stop
    end

    def kill(error = nil)
      if Sorge.test_mode
        @server.stop
        @engine.kill
      else
        @server.stop
        exit(error.nil?)
      end
    end

    def env
      @options[:env]
    end

    def dryrun?
      @options[:dryrun]
    end

    private

    def setup_trap
      trap(:INT) do
        trap(:INT) { Thread.new { kill } } # kill application at second time
        Thread.new do
          Sorge.logger.info('going to gracefully shutdown sorge...')
          Sorge.logger.info('Ctrl-C again if you want to immediately shutdown')
          stop
        end
      end
    end

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

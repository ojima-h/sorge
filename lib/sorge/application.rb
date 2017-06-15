module Sorge
  class Application
    extend Forwardable

    DEFAULT_OPTIONS = {
      sorgefile: nil,
      env: 'development',
      dryrun: false,
      savepoint: true
    }.freeze

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)

      @dsl = DSL.new(self)
      @engine = Engine.new(self)
      @server = Server.new(self)

      @config = OpenStruct.new

      # In Sorgefile:
      #   - setup blocks are registered
      #   - tasks are declared
      #   - plugins are loaded
      load_sorgefile

      @plugins = Plugin.build(self)
      setup
      @dsl.tasks.build
    end
    attr_reader :config, :dsl, :engine, :server, :plugins
    def_delegators :@dsl, :tasks
    def_delegators :'@engine',
                   :worker, :submit, :resume, :run, :stop, :wait_stop

    def setup
      Sorge.setup.each { |block| block.call(self) }
      assign_default_config
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
      @options[:environment]
    end

    def dryrun?
      @options[:dryrun]
    end

    def savepoint?
      @options[:savepoint]
    end

    private

    def assign_default_config
      @config.app_name           ||= 'sorge'
      @config.heartbeat_interval ||= dryrun? ? 0.1 : 1
      @config.process_dir        ||= './var/sorge'

      dir = @config.process_dir
      @config.savepoint_path     ||= File.join(dir, 'savepoints')
      @config.server_info_path   ||= File.join(dir, 'server-info.yml')
    end

    def setup_trap
      return if Sorge.test_mode
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

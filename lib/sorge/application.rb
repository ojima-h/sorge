module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @options = options
      @config = ConfigLoader.new(options).load
      @env = options[:environment]

      load_sorgefile
      @plugins = Plugin.build(self)

      @engine = Engine.new(self)
      @server = Server.new(self)
    end
    attr_reader :config, :env, :engine, :config, :server, :plugins
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run, :resume

    def shutdown
      @server.stop
      @engine.driver.shutdown
    end

    def kill(error)
      @server.stop
      @engine.driver.kill(error)
    end

    def name
      config.app_name
    end

    def dryrun?
      @options[:dryrun]
    end

    private

    def load_sorgefile
      sorgefile = find_sorgefile
      require(sorgefile) if sorgefile
    end

    def find_sorgefile
      return config.sorgefile if config.sorgefile

      %w(Sorgefile Sorgefile.rb).each do |filename|
        return File.expand_path(filename) if File.file?(filename)
      end

      nil
    end
  end
end

require 'sorge/engine'
require 'sorge/plugin'
require 'sorge/server'

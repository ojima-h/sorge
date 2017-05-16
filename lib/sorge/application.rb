module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @options = options
      @config = ConfigLoader.new(options).load
      @env = options[:environment]

      @dsl = DSL.new(self)
      load_sorgefile
      @dsl.tasks.build

      @engine = Engine.new(self)
      @server = Server.new(self)
      @plugins = Plugin.build(self)
    end
    attr_reader :config, :env, :dsl, :engine, :config, :server, :plugins
    def_delegators :@dsl, :tasks
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run, :resume

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

    def dryrun?
      @options[:dryrun]
    end

    private

    def load_sorgefile
      sorgefile = find_sorgefile
      require(File.expand_path(sorgefile)) if sorgefile
    end

    def find_sorgefile
      return config.sorgefile if config.sorgefile

      %w(Sorgefile Sorgefile.rb).each do |filename|
        return filename if File.file?(filename)
      end

      nil
    end
  end
end

require 'sorge/engine'
require 'sorge/plugin'
require 'sorge/server'

module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @config = ConfigLoader.new(options).load
      @env = options[:environment]
      @exit_on_terminate = options.fetch(:exit_on_terminate, true)

      @dsl = DSL.new(self)
      @sorgefile = find_sorgefile
      @dsl.load_sorgefile(@sorgefile) if @sorgefile

      @engine = Engine.new(self)
      @server = Server.new(self)
    end
    attr_reader :config, :env, :dsl, :engine, :config, :server
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

    private

    def find_sorgefile
      return config.sorgefile if config.sorgefile

      %w(Sorgefile Sorgefile.rb).each do |filename|
        return filename if File.file?(filename)
      end

      nil
    end
  end
end

require 'sorge/dsl'
require 'sorge/engine'
require 'sorge/server'

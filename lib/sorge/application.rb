module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @config = options[:config] || Config.new(options)
      @exit_on_terminate = options.fetch(:exit_on_terminate, true)

      @dsl = DSL.new(self)
      @sorgefile = find_sorgefile
      @dsl.load_sorgefile(@sorgefile) if @sorgefile

      @engine = Engine.new(self)
    end
    attr_reader :config, :dsl, :engine, :config
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run, :resume

    def shutdown
      @engine.driver.shutdown
      Process.kill(:TERM, 0) if @exit_on_terminate
    end

    def kill(error)
      @engine.driver.kill(error)
      Process.kill(:TERM, 0) if @exit_on_terminate
    end

    def name
      @name ||= @config.get('core.app_name')
    end

    private

    def find_sorgefile
      config.get('core.sorgefile').tap { |f| return f if f }

      %w(Sorgefile Sorgefile.rb).each do |filename|
        return filename if File.file?(filename)
      end

      nil
    end
  end
end

require 'sorge/dsl'
require 'sorge/engine'

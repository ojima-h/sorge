module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @config = options[:config] || Config.new(options)

      @dsl = DSL.new(self)
      @sorgefile = find_sorgefile
      @dsl.load_sorgefile(@sorgefile) if @sorgefile

      @engine = Engine.new(self)
    end
    attr_reader :config, :dsl, :engine, :config
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run

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

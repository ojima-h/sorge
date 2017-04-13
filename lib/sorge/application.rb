module Sorge
  class Application
    extend Forwardable

    def initialize(options = {})
      @config = options[:config] || Config.new(options)

      @dsl = DSL.new(self)
      @engine = Engine.new(self)

      load_sorgefile
    end
    attr_reader :config, :dsl, :engine, :config
    def_delegators :'@engine.driver', :kill, :shutdown, :submit, :run

    private

    def load_sorgefile
      @sorgefile = find_sorgefile
      @dsl.with_current { load(@sorgefile) } if @sorgefile
    end

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

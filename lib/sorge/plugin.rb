module Sorge
  def self.plugins
    @plugins ||= OpenStruct.new
  end

  class Plugin
    def self.register(name)
      Sorge.plugins[name.to_sym] = self
    end

    def self.build(app)
      plugins = OpenStruct.new
      Sorge.plugins.each_pair do |name, klass|
        plugins[name] = klass.new(app)
      end
      plugins
    end

    def initialize(app)
      @app = app
      setup
    end
    attr_reader :app

    def setup; end
  end
end

require 'sorge/plugin/command'

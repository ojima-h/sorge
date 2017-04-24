module Sorge
  class Plugin
    class << self
      def plugins
        @plugins ||= OpenStruct.new
      end

      def build(app)
        ret = OpenStruct.new
        plugins.each_pair do |name, klass|
          ret[name] = klass.new(app)
        end
        ret
      end
    end

    class Base
      def self.register(name)
        name = name.to_sym

        Plugin.plugins[name] = self

        if (app = DSL.current)
          app.plugins[name] ||= new(app)
        end
      end

      def initialize(app)
        @app = app
        setup
      end
      attr_reader :app

      def setup; end
    end
  end
end

require 'sorge/plugin/command'

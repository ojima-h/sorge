module Sorge
  class Plugin
    class << self
      def plugins
        @plugins ||= OpenStruct.new
      end

      def build(app)
        ret = OpenStruct.new
        plugins.each_pair do |name, klass|
          ret[name] = klass.new(app).tap(&:setup)
        end
        ret
      end
    end

    class Base
      def self.register(name)
        Plugin.plugins[name.to_sym] = self
      end

      def initialize(app)
        @app = app
      end
      attr_reader :app

      def setup; end
    end
  end
end

require 'sorge/plugin/command'

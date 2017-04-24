module Sorge
  class Plugin
    class << self
      def plugins
        @plugins ||= OpenStruct.new
      end

      def build(application)
        ret = OpenStruct.new
        plugins.each_pair do |name, klass|
          ret[name] = klass.new(application).tap(&:setup)
        end
        ret
      end
    end

    class Base
      def self.register(name)
        Plugin.plugins[name.to_sym] = self
      end

      def initialize(application)
        @application = application
      end
      attr_reader :application

      def setup; end
    end
  end
end

require 'sorge/plugin/command'

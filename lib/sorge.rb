require 'English'
require 'fileutils'
require 'forwardable'
require 'json'
require 'monitor'
require 'ostruct'
require 'singleton'
require 'socket'
require 'time'
require 'yaml'

require 'concurrent'

require 'sorge/dsl'
require 'sorge/application'
require 'sorge/util'
require 'sorge/version'

module Sorge
  class Error < StandardError; end
  class AlreadyStopped < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new($stderr).tap do |logger|
        logger.progname = 'sorge'
        logger.level = Logger::Severity::INFO
      end
    end
    attr_writer :logger

    def setup(&block)
      @setup ||= []
      block_given? ? @setup << block : @setup
    end

    attr_accessor :test_mode
  end
end

# for jruby compatibility
ServerSocket = Socket unless defined?(ServerSocket)

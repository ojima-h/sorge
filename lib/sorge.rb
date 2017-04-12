require 'fileutils'
require 'forwardable'
require 'json'
require 'monitor'
require 'yaml'

require 'concurrent'

require 'sorge/application'
require 'sorge/config'
require 'sorge/util'
require 'sorge/version'

module Sorge
  class Error < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new($stderr).tap do |logger|
        logger.progname = 'sorge'
      end
    end
    attr_writer :logger
  end
end

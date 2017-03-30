require 'sinatra/base'

require 'sorge'

require 'sorge/server/helper'
require 'sorge/server/base'

module Sorge
  class Server
    def self.build(application, &block)
      Class.new(Base) do
        set :sorge, application

        set :port, application.config.get('server.port')

        class_eval(&block) if block_given?
      end
    end

    def self.create(options = {}, &block)
      app = Sorge::Application.new(options)
      build(app, &block)
    end
  end
end

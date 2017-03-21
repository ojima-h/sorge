module Sorge
  class Engine
    extend Forwardable

    def initialize(application)
      @application = application
      @driver = Driver.new(self)
      @worker = Worker.new(self)
    end
    attr_reader :application, :driver, :worker

    def_delegators 'application.dsl', :task_graph
  end
end

require 'sorge/engine/batch'
require 'sorge/engine/driver'
require 'sorge/engine/job_status'
require 'sorge/engine/job'
require 'sorge/engine/worker'

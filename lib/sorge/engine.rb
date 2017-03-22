module Sorge
  class Engine
    extend Forwardable

    def initialize(application)
      @application = application
      @executor = Executor.new(self)
      @driver = Driver.new(self)
      @stash = Stash.new(self)
      @worker = Worker.new(self)
    end
    attr_reader :application, :executor, :driver, :stash, :worker

    def_delegators 'application.dsl', :task_graph
  end
end

require 'sorge/engine/batch'
require 'sorge/engine/driver'
require 'sorge/engine/executor'
require 'sorge/engine/job_status'
require 'sorge/engine/job'
require 'sorge/engine/stash'
require 'sorge/engine/worker'

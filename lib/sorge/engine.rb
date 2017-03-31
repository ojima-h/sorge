module Sorge
  class Engine
    def initialize(application)
      @application = application
      @executor = Executor.new(self)
      @driver = Driver.new(self)
      @state_manager = StateManager.new(self)
      @worker = Worker.new(self)
    end
    attr_reader :application, :executor, :driver, :state_manager, :worker
  end
end

require 'sorge/engine/jobflow'
require 'sorge/engine/jobflow_builder'
require 'sorge/engine/driver'
require 'sorge/engine/executor'
require 'sorge/engine/job_status'
require 'sorge/engine/job'
require 'sorge/engine/state_manager'
require 'sorge/engine/worker'

module Sorge
  class Engine
    extend Forwardable

    def initialize(application)
      @application = application
      @driver = Driver.new(self)
      @job_manager = JobManager.new(self)
      @worker = Worker.new(self)
    end
    attr_reader :application, :driver, :job_manager, :worker

    def_delegators 'application.dsl', :task_graph
  end
end

require 'sorge/engine/driver'
require 'sorge/engine/job_manager'
require 'sorge/engine/job_status'
require 'sorge/engine/job'
require 'sorge/engine/worker'

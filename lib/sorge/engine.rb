module Sorge
  class Engine
    extend Forwardable

    def initialize(application)
      @application = application
      @config = application.config

      @worker = Worker.new(self)
      @driver = Driver.new(self)
      @jobflow_operator = JobflowOperator.new(self)
      @savepoint = Savepoint.new(self)

      @local = false
    end
    attr_reader :application, :config,
                :driver, :savepoint, :worker, :jobflow_operator
    def_delegators :@driver, :kill, :shutdown, :run, :submit, :resume
    attr_accessor :local
    alias local? local
  end
end

require 'sorge/engine/async_worker'
require 'sorge/engine/driver'
require 'sorge/engine/jobflow_operator'
require 'sorge/engine/jobflow_status'
require 'sorge/engine/pane'
require 'sorge/engine/savepoint'
require 'sorge/engine/task_operator'
require 'sorge/engine/task_status'
require 'sorge/engine/timeout_queue'
require 'sorge/engine/worker'

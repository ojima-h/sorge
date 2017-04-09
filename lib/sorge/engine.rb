module Sorge
  class Engine
    def initialize(application)
      @application = application
      @event_queue = EventQueue.new(self)
      @executor = Executor.new(self)
      @driver = Driver.new(self)
      @savepoint = Savepoint.new(self)
      @state_manager = StateManager.new(self)
      @task_runner = TaskRunner.new(self)
      @worker = Worker.new(self)

      @task_states = Hash.new { |hash, key| hash[key] = {} }
    end
    attr_reader :application, :event_queue, :executor, :driver, :savepoint,
                :state_manager, :task_runner, :worker,
                :task_states

    def kill
      @worker.kill
      @driver.kill
    end
  end
end

require 'sorge/engine/agent'
require 'sorge/engine/event_queue'
require 'sorge/engine/jobflow'
require 'sorge/engine/jobflow_builder'
require 'sorge/engine/driver'
require 'sorge/engine/executor'
require 'sorge/engine/job_status'
require 'sorge/engine/job'
require 'sorge/engine/savepoint'
require 'sorge/engine/state_manager'
require 'sorge/engine/task_handler'
require 'sorge/engine/task_runner'
require 'sorge/engine/task_state'
require 'sorge/engine/worker'

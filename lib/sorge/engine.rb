module Sorge
  class Engine
    extend Forwardable

    def initialize(application)
      @application = application
      @config = application.config

      @worker = Worker.new(self)
      @event_queue = EventQueue.new(self)
      @driver = Driver.new(self)
      @savepoint = Savepoint.new(self)
      @task_runner = TaskRunner.new(self)

      @task_states = Hash.new { |hash, key| hash[key] = {} }
      @mon = Monitor.new
    end
    attr_reader :application, :config, :event_queue, :driver,
                :savepoint, :task_runner, :worker,
                :task_states
    def_delegators :@mon, :synchronize
    def_delegators :@driver, :kill, :shutdown, :run, :submit
  end
end

require 'sorge/engine/event_queue'
require 'sorge/engine/driver'
require 'sorge/engine/savepoint'
require 'sorge/engine/task_handler'
require 'sorge/engine/task_runner'
require 'sorge/engine/worker'

module Sorge
  class Engine
    extend Forwardable

    def initialize(app)
      @app = app
      @config = app.config

      @worker = Worker.new(self)
      @jobflow_operator = JobflowOperator.new(self)
      @savepoint = Savepoint.new(self)
    end
    attr_reader :app, :config, :savepoint, :worker, :jobflow_operator
    def_delegators :@jobflow_operator, :start, :stop, :wait_stop

    def submit(task_name, time)
      @app.tasks.validate_name(task_name)
      @jobflow_operator.submit(task_name, time)
    end

    def run(task_name, time)
      @app.tasks.validate_name(task_name)
      @jobflow_operator.run(task_name, time)
    end

    def resume(file_path = 'latest')
      data = @savepoint.read(file_path)
      @jobflow_operator.resume(data)
    end

    def kill
      @jobflow_operator.kill
      @worker.kill
    end
  end
end

require 'sorge/engine/async_worker'
require 'sorge/engine/jobflow_operator'
require 'sorge/engine/jobflow_status'
require 'sorge/engine/pane'
require 'sorge/engine/savepoint'
require 'sorge/engine/task_operator'
require 'sorge/engine/task_status'
require 'sorge/engine/timeout_queue'
require 'sorge/engine/worker'

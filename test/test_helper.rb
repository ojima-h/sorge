$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'sorge'
require 'minitest/autorun'

# # Disable Sorge logger
# Sorge.logger = Logger.new(nil)

# Enable Concurrent gem logger
Concurrent.use_stdlib_logger(Logger::DEBUG)

class SorgeTest < Minitest::Test
  attr_reader :app

  def self.spy
    @spy ||= []
  end

  def run(*args, &block)
    @app = Sorge::Application.new
    load File.expand_path('../Sorgefile.rb', __FILE__)

    @app.model.database[:event_queue].delete
    SorgeTest.spy.clear

    super
  end

  #
  # Helpers
  #
  def tasks
    app.dsl.task_manager
  end

  def jobs
    app.engine.job_manager
  end

  def invoke(task, params = {})
    t = task.is_a?(Sorge::DSL::Task) ? t : tasks[task]
    app.engine.driver.invoke(t, params)
  end
end

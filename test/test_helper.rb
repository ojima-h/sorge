$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RACK_ENV'] = 'test'

require 'sorge'
require 'minitest/autorun'
require 'tempfile'

# # Disable Sorge logger
# Sorge.logger = Logger.new(nil)

# Enable Concurrent gem logger
Concurrent.use_stdlib_logger(Logger::DEBUG)

class SorgeTest < Minitest::Test
  attr_reader :app

  Spy = Struct.new(:name, :params)

  def self.spy(name = nil, params = {})
    @spy ||= []
    return @spy if name.nil?
    @spy << Spy[name, params]
  end

  def spy(name, params = {})
    Spy[name, params]
  end

  def self.hook(name = nil, &block)
    @hooks ||= {}
    @hooks[name] = block if block_given?
    @hooks
  end

  def setup
    SorgeTest.spy.clear
    SorgeTest.hook.clear

    @app = Sorge::Application.new(
      sorgefile: File.expand_path('../Sorgefile.rb', __FILE__),
      exit_on_terminate: false
    )
  end

  def teardown
    return unless @app

    @app.kill('test finish')
    clear_savepoint
  end

  def clear_savepoint
    f = @app.config.get('core.savepoint_path')
    FileUtils.rm_r(f) if File.exist?(f)
  rescue
    nil # this may fail if a new savepoint is created while cleaning.
  end

  #
  # Helpers
  #
  def tasks
    app.dsl.task_manager
  end

  def invoke(task_name, time = nil)
    app.submit(task_name, time || Time.now.to_i).shutdown
  end
end

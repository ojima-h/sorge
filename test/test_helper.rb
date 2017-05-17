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

  def self.spy(params = {})
    @spy ||= []
    return @spy if params.empty?
    @spy << OpenStruct.new(params)
  end

  def self.hook(name = nil, &block)
    @hooks ||= {}
    @hooks[name] = block if block_given?
    @hooks
  end

  def self.process_dir_lock(&block)
    @mutex ||= Mutex.new
    @mutex.synchronize(&block)
  end

  def setup
    SorgeTest.spy.clear
    SorgeTest.hook.clear

    @app = Sorge::Application.new(
      sorgefile: File.expand_path('../Sorgefile.rb', __FILE__)
    )
  end

  def teardown
    return unless @app

    @app.kill
    clear_savepoint
  end

  def clear_savepoint
    SorgeTest.process_dir_lock do
      f = @app.config.savepoint_path
      FileUtils.rm_r(f) if File.exist?(f)
    end
  end

  #
  # Helpers
  #
  def invoke(task_name, time = nil)
    app.run(task_name, time || now)
  end

  def now
    @now ||= Time.now
  end
end

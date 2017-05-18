$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RACK_ENV'] = 'test'

require 'sorge'
require 'minitest/autorun'
require 'tempfile'

Sorge.test_mode = true

# Sorge logger setting:
# Sorge.logger = Logger.new(nil) # Disable Sorge logger
# Sorge.logger.level = Logger::Severity::DEBUG

# Enable Concurrent gem logger
Concurrent.use_stdlib_logger(Logger::DEBUG)

TEST_DIR = File.expand_path('../../var/sorge-test', __FILE__)
FileUtils.rm_r(TEST_DIR) if File.exist?(TEST_DIR)

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

  def setup
    SorgeTest.spy.clear
    SorgeTest.hook.clear

    build_app
  end

  def teardown
    return unless @app

    @app.kill
  end

  def build_app
    @app = Sorge::Application.new(
      sorgefile: File.expand_path('../Sorgefile.rb', __FILE__)
    )

    process_dir = File.join(TEST_DIR, Sorge::Util.generate_id)

    @app.config.process_dir      = process_dir
    @app.config.savepoint_path   = File.join(process_dir, 'savepoints')
    @app.config.server_info_path = File.join(process_dir, 'server-info.yml')
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

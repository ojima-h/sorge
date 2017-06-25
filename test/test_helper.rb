require 'sorge'
require 'minitest/autorun'
require 'tempfile'

Sorge.test_mode = true

# Sorge logger setting:
# Sorge.logger = Logger.new(nil) # Disable Sorge logger
# Sorge.logger.level = Logger::Severity::DEBUG

# Enable Concurrent gem logger
Concurrent.use_stdlib_logger(Logger::DEBUG)

class SorgeTest < Minitest::Test
  SORGEFILE = File.expand_path('../Sorgefile.rb', __FILE__)

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

    @app = Sorge::Application.new(sorgefile: SORGEFILE)
    @app.engine.jobflow_operator.start
  end
  attr_reader :app

  def teardown
    @app.kill if @app
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

  def runcli(*args)
    root = File.expand_path('../..', __FILE__)
    binpath = File.join(root, 'exe/sorge')
    options = [
      '-f', File.join(root, 'test/Sorgefile'),
      '-C', root
    ]
    system(binpath, *args, *options)
  end
end

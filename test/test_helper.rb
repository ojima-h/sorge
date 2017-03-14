$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'sorge'
require 'minitest/autorun'

class SorgeTest < Minitest::Test
  attr_reader :app

  def self.spy
    @spy ||= []
  end

  def tasks
    app.dsl.task_manager
  end

  def run(*args, &block)
    @app = Sorge::Application.new
    load File.expand_path('../Sorgefile.rb', __FILE__)

    @app.model.database[:event_queue].delete
    self.class.spy.clear

    super
  end
end

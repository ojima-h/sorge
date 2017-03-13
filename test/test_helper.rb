$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'sorge'
require 'minitest/autorun'

class SorgeTest < Minitest::Test
  attr_reader :app

  def run(*args, &block)
    @app = Sorge::Application.new
    @app.model.database[:event_queue].delete
    super
  end
end

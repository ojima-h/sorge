require 'test_helper'
require 'sorge/server'

require 'rack/test'

module Sorge
  class ServerTest < SorgeTest
    include Rack::Test::Methods

    alias sorge app

    def app
      Sorge::Server.build(sorge)
    end

    def post_json(uri, params = {}, env = {}, &block)
      post(uri, JSON.dump(params), env, &block)
    end

    def test_version
      get('version')
      assert last_response.ok?
      assert_equal Sorge::VERSION, last_response.body
    end

    def test_invoke
      post_json('jobs', task: 't1', async: false)
      assert last_response.ok?
    end
  end
end
